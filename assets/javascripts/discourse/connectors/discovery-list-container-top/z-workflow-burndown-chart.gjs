import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import loadChartJS from "discourse/lib/load-chart-js";
import { i18n } from "discourse-i18n";

export default class WorkflowBurndownChartConnector extends Component {
  @service dialog;
  @service discovery;
  @service router;

  @tracked chartPayload = null;
  @tracked isLoading = false;
  @tracked errorMessage = null;
  @tracked selectedWeeks = 2;

  chart = null;
  chartCanvas = null;

  willDestroy(...args) {
    super.willDestroy(...args);
    this.chart?.destroy();
    this.chart = null;
  }

  get routeTopicList() {
    const routeAttributes = this.router.currentRoute?.attributes;

    return (
      routeAttributes?.list ||
      routeAttributes?.model?.list ||
      routeAttributes?.model ||
      routeAttributes
    );
  }

  get topicList() {
    return this.routeTopicList || this.discovery.currentTopicList;
  }

  get topicListMetadata() {
    try {
      return this.topicList?.topic_list || this.topicList;
    } catch {
      return this.topicList;
    }
  }

  get currentLocation() {
    this.router.currentURL;

    if (typeof window !== "undefined") {
      return `${window.location.pathname}${window.location.search}`;
    }

    return this.router.currentURL || "";
  }

  get currentPathname() {
    return this.currentLocation.split("?")[0];
  }

  get currentSearchParams() {
    const queryString = this.currentLocation.split("?")[1] || "";
    return new URLSearchParams(queryString);
  }

  get hasWorkflowFilter() {
    return this.topicList?.filter?.toString() === "workflow";
  }

  get isWorkflowRoute() {
    return (
      this.hasWorkflowFilter ||
      this.router.currentRouteName?.startsWith("discovery.workflow") ||
      this.currentPathname.startsWith("/workflow") ||
      this.currentPathname.startsWith("/filter/workflow")
    );
  }

  get isWorkflowChartsRoute() {
    return (
      this.router.currentRouteName === "discovery.workflowCharts" ||
      this.currentPathname.startsWith("/workflow/charts")
    );
  }

  get isChartView() {
    return (
      this.currentSearchParams.get("workflow_view") === "chart" ||
      this.isWorkflowChartsRoute
    );
  }

  get singleWorkflowId() {
    return Number(this.topicListMetadata?.workflow_single_workflow_id) || null;
  }

  get canUseChartView() {
    return (
      this.topicListMetadata?.workflow_can_view_charts === true &&
      this.singleWorkflowId !== null
    );
  }

  get shouldRenderChart() {
    return this.isWorkflowRoute && this.isChartView && this.canUseChartView;
  }

  get hasChartData() {
    return (this.chartPayload?.series || []).length > 0;
  }

  get chartSeries() {
    return (this.chartPayload?.series || []).map((series) => {
      const color = this.asHexColor(series.color);
      return {
        ...series,
        color_style: color ? `background-color: ${color};` : null,
      };
    });
  }

  get pointCount() {
    return (this.chartPayload?.labels || []).length;
  }

  get selectedWorkflowName() {
    return this.chartPayload?.selected_workflow_name || null;
  }

  normalizedWeeks(value) {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 1) {
      return 2;
    }

    return Math.min(parsed, 12);
  }

  asHexColor(rawColor) {
    if (!rawColor) {
      return null;
    }

    const normalized = String(rawColor).trim().replace(/^#/, "");
    if (!normalized.match(/^[0-9A-Fa-f]{3}$|^[0-9A-Fa-f]{6}$/)) {
      return null;
    }

    return `#${normalized}`;
  }

  @action
  initialize() {
    this.syncFromUrl();
  }

  @action
  syncFromUrl() {
    if (!this.isWorkflowRoute || !this.isChartView) {
      return;
    }

    if (!this.canUseChartView) {
      const params = Object.fromEntries(this.currentSearchParams.entries());
      delete params.workflow_view;
      this.router.transitionTo("discovery.workflow", {
        queryParams: {
          my_categories: params.my_categories || null,
          overdue: params.overdue || null,
          overdue_days: params.overdue_days || null,
          workflow_step_position: params.workflow_step_position || null,
          chart_weeks: params.chart_weeks || null,
          workflow_view: null,
        },
      });
      return;
    }

    const params = this.currentSearchParams;
    this.selectedWeeks = this.normalizedWeeks(params.get("chart_weeks"));
    this.loadChartData();
  }

  @action
  captureCanvas(element) {
    this.chartCanvas = element;
    this.renderChart();
  }

  async loadChartData() {
    this.isLoading = true;
    this.errorMessage = null;

    try {
      this.chartPayload = await ajax("/discourse-workflow/charts.json", {
        data: {
          weeks: this.selectedWeeks,
          workflow_id: this.singleWorkflowId,
        },
      });

      await this.renderChart();
    } catch (error) {
      this.errorMessage = extractError(error);
      this.chart?.destroy();
      this.chart = null;
      await this.dialog.alert(this.errorMessage);
    } finally {
      this.isLoading = false;
    }
  }

  async renderChart() {
    if (!this.chartCanvas || !this.hasChartData) {
      return;
    }

    const Chart = await loadChartJS();
    this.chart?.destroy();
    const labels = this.chartPayload.labels || [];
    const showDayInitialTicks = this.selectedWeeks <= 3;
    const tickLabelForIndex = (index) => {
      const label = labels[index];
      if (!label) {
        return "";
      }

      const date = new Date(label);
      if (Number.isNaN(date.getTime())) {
        return "";
      }

      if (showDayInitialTicks) {
        return date
          .toLocaleDateString(undefined, { weekday: "short" })
          .charAt(0)
          .toUpperCase();
      }

      return `${date.getMonth() + 1}/${date.getDate()}`;
    };

    this.chart = new Chart(this.chartCanvas.getContext("2d"), {
      type: "line",
      data: {
        labels,
        datasets: this.chartSeries.map((series) => {
          const color = this.asHexColor(series.color) || "#7a7a7a";

          return {
            label: `${series.step_position}. ${series.step_name}`,
            data: series.data || [],
            borderColor: color,
            backgroundColor: color,
            pointRadius: 3,
            pointHoverRadius: 5,
            pointHitRadius: 8,
            borderWidth: 2,
            tension: 0.2,
          };
        }),
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false,
        },
        plugins: {
          legend: { display: false },
          tooltip: { enabled: true },
        },
        scales: {
          x: {
            offset: true,
            grid: {
              offset: true,
            },
            ticks: {
              autoSkip: !showDayInitialTicks,
              maxTicksLimit: 14,
              align: "center",
              maxRotation: 0,
              minRotation: 0,
              callback: (value, index) => tickLabelForIndex(index),
            },
          },
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0,
            },
            title: {
              display: true,
              text: i18n("discourse_workflow.charts.y_axis_count"),
            },
          },
        },
      },
    });
  }

  <template>
    {{#if this.shouldRenderChart}}
      <section
        class="discovery-list-container-top-outlet workflow-burndown"
        {{didInsert this.initialize}}
        {{didUpdate this.syncFromUrl this.currentLocation}}
      >
        <h3 class="workflow-burndown__title">
          {{i18n "discourse_workflow.charts.title"}}
        </h3>

        {{#if this.selectedWorkflowName}}
          <p class="workflow-burndown__workflow-name">
            {{i18n
              "discourse_workflow.charts.workflow_name"
              workflow_name=this.selectedWorkflowName
            }}
          </p>
        {{/if}}

        {{#if this.isLoading}}
          <p class="workflow-burndown__status">
            {{i18n "discourse_workflow.charts.loading"}}
          </p>
        {{/if}}

        {{#if this.errorMessage}}
          <p class="workflow-burndown__status workflow-burndown__status--error">
            {{this.errorMessage}}
          </p>
        {{/if}}

        {{#if this.hasChartData}}
          <div
            class="workflow-burndown__chart"
            data-point-count={{this.pointCount}}
          >
            <canvas {{didInsert this.captureCanvas}}></canvas>
          </div>

          <div class="workflow-burndown__legend">
            {{#each this.chartSeries as |series|}}
              <div class="workflow-burndown__legend-step">
                <span
                  class="workflow-burndown__legend-color"
                  style={{series.color_style}}
                ></span>
                <span>
                  {{series.step_position}}.
                  {{series.step_name}}
                </span>
              </div>
            {{/each}}
          </div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
