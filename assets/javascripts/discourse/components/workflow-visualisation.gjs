import Component from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import loadScript from "discourse/lib/load-script";
import { i18n } from "discourse-i18n";

export default class WorkflowVisualisationComponent extends Component {
  ensureD3() {
    return loadScript("/plugins/discourse-workflow/d3/d3.min.js");
  }

  async fetchData(topic_id) {
    return ajax(`/discourse-workflow/visualisation/${topic_id}`).catch(
      (err) => {
        popupAjaxError(err);
      }
    );
  }

  @action
  async setup() {
    await this.ensureD3();
    const result = await this.fetchData(this.model.topic_id);

    const workflowData = {
      lanes: result.lanes,
      nodes: result.nodes,
      links: result.links,
    };

    // Set up the SVG canvas dimensions
    const width = 950;
    const height = 700;
    const laneHeight = height / workflowData.lanes.length;
    const nodeSpacing = width / (workflowData.nodes.length + 1);
    const nodeWidth = nodeSpacing / 2;
    const nodeHeight = laneHeight / 3;

    // Select the SVG container
    const svg = window.d3
      .select("#workflow-visualisation")
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`);

    // Draw swim lanes
    const lanes = svg
      .selectAll(".lane")
      .data(workflowData.lanes)
      .enter()
      .append("g");

    lanes
      .append("rect")
      .attr("class", "lane")
      .attr("x", 0)
      .attr("y", (d, i) => i * laneHeight)
      .attr("width", width)
      .attr("height", laneHeight)
      .style("stroke-width", width / 200);

    lanes
      .append("a")
      .attr("xlink:href", (d) => d.link)
      .attr("target", "_blank")
      .append("text")
      .attr("class", "lane-label")
      .attr("x", width / 100)
      .attr("y", (d, i) => i * laneHeight + laneHeight / 2)
      .style("font-size", `${height / 40}px`)
      .text((d) => d.name);

    // Define arrow marker
    svg
      .append("defs")
      .append("marker")
      .attr("id", "arrowhead")
      .attr("viewBox", `0 -${width / 200} ${width / 100} ${width / 100}`)
      .attr("refX", 10)
      .attr("refY", 0)
      .attr("markerWidth", width / 150)
      .attr("markerHeight", width / 150)
      .attr("orient", "auto-start-reverse")
      .append("path")
      .attr("d", `M0,-${width / 200}L${width / 100},0L0,${width / 200}`)
      .attr("class", "arrowhead")
      .attr("z-index", 100);

    // Add links to the SVG
    const link = svg
      .append("g")
      .attr("class", "links")
      .selectAll("path")
      .data(workflowData.links)
      .enter()
      .append("path")
      .style("stroke-width", width / 400)
      .attr("class", "link")
      .attr("marker-end", "url(#arrowhead)");

    // Add labels to links
    const linkLabels = svg
      .append("g")
      .attr("class", "link-labels")
      .selectAll("text")
      .data(workflowData.links)
      .enter()
      .append("text")
      .attr("class", "link-label")
      .attr("text-anchor", "middle")
      .style("font-size", `${height / 50}px`)
      .text((d) => d.action);

    // Add nodes to the SVG
    svg
      .append("g")
      .attr("class", "nodes")
      .selectAll("rect")
      .data(workflowData.nodes)
      .enter()
      .append("rect")
      .attr("class", (d) => (d.active ? "node active" : "node"))
      .attr("fill", (d) => (d.active ? "#ffa500" : "#69b3a2"))
      .style("stroke-width", width / 400)
      .attr("width", nodeWidth)
      .attr("height", nodeHeight)
      .attr("rx", width / 200)
      .attr("ry", width / 200)
      .attr("x", (d, i) => nodeSpacing * (i + 1))
      .attr("y", (d) => d.lane * laneHeight + laneHeight / 2 - nodeHeight / 2);

    // Add labels to nodes
    svg
      .append("g")
      .attr("class", "labels")
      .selectAll("text")
      .data(workflowData.nodes)
      .enter()
      .append("text")
      .attr("text-anchor", "middle")
      .attr("x", (d, i) => nodeSpacing * (i + 1) + nodeWidth / 2)
      .attr("y", (d) => d.lane * laneHeight + laneHeight / 2 + height / 200)
      .style("font-size", `${height / 50}px`)
      .text((d) => d.id);

    // Update links layout
    link.attr("d", (d) => {
      const sourceIndex = workflowData.nodes.findIndex(
        (node) => node.id === d.source
      );
      const targetIndex = workflowData.nodes.findIndex(
        (node) => node.id === d.target
      );
      const sourceX = nodeSpacing * (sourceIndex + 1) + nodeWidth;
      const sourceTopY =
        workflowData.nodes[sourceIndex].lane * laneHeight +
        laneHeight / 2 -
        nodeHeight / 2;
      const sourceY =
        workflowData.nodes[sourceIndex].lane * laneHeight + laneHeight / 2;
      const targetX = nodeSpacing * (targetIndex + 1);
      const targetY =
        workflowData.nodes[targetIndex].lane * laneHeight + laneHeight / 2;
      const targetBottomY =
        workflowData.nodes[targetIndex].lane * laneHeight +
        laneHeight / 2 +
        nodeHeight / 2;

      // Handle returning links - rotated S shape
      if (sourceIndex > targetIndex) {
        const midY =
          sourceIndex > targetIndex + 1
            ? targetBottomY + laneHeight / 5
            : sourceTopY - (sourceTopY - targetBottomY) / 2; // Midpoint between source and target nodes
        return `M${sourceX - nodeWidth / 2},${sourceTopY} V${midY} H${
          targetX + nodeWidth / 2
        } V${targetBottomY}`;
      }

      // Forward links (Z shape)
      return `M${sourceX},${sourceY} H${
        (sourceX + targetX) / 2
      } V${targetY} H${targetX}`;
    });

    linkLabels
      .attr("x", (d) => {
        const sourceIndex = workflowData.nodes.findIndex(
          (node) => node.id === d.source
        );
        const targetIndex = workflowData.nodes.findIndex(
          (node) => node.id === d.target
        );
        const sourceX = nodeSpacing * (sourceIndex + 1) + nodeWidth / 2;
        if (sourceIndex > targetIndex) {
          return sourceX - nodeWidth / 4;
        }

        const targetX = nodeSpacing * (targetIndex + 1);
        return (sourceX + targetX) / 2;
      })
      .attr("y", (d) => {
        const sourceIndex = workflowData.nodes.findIndex(
          (node) => node.id === d.source
        );
        const targetIndex = workflowData.nodes.findIndex(
          (node) => node.id === d.target
        );
        const sourceY =
          workflowData.nodes[sourceIndex].lane * laneHeight + laneHeight / 2;

        if (sourceIndex > targetIndex) {
          return sourceY - laneHeight / 3.333;
        }

        return sourceY + laneHeight / 4;
      });
  }

  get title() {
    return i18n("discourse_workflow.topic_banner.visualisation_title", {
      workflow_name: this.model.workflow_name,
    });
  }

  <template>
    {{#if @showTitle}}
      <h1>{{this.title}}</h1>
    {{/if}}
    <div id="workflow-visualisation" {{didInsert this.setup}}></div>
  </template>
}
