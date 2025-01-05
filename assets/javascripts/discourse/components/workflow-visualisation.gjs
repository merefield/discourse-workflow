import loadScript from "discourse/lib/load-script";
import DiscourseURL from "discourse/lib/url";
import { notEmpty, alias } from "@ember/object/computed";
import { observes } from 'discourse-common/utils/decorators';
import Component from "@ember/component";
import DModal from "discourse/components/d-modal";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class WorkflowVisualisationModalComponent extends Component {
  // classNames: "user-network-vis",
  // results: alias("model.results"),
  // hasItems: notEmpty("results"),

  ensureD3() {
    return loadScript("/plugins/discourse-workflow/d3/d3.min.js");
  }

  async fetchData(topic_id) {
    return ajax(`/discourse-workflow/visualisation/${topic_id}`)
      .catch((err) =>
      {
        popupAjaxError(err)
      });
  }


  // didInsertElement() {
  //   if (!this.site.mobileView) {
  //     this.waitForData()
  //   }
  // },

  // @observes("hasItems")
  // waitForData() {
  //   if(!this.hasItems) {
  //     return;
  //   } else {
  //     this.setup();
  //   }
  // },

  @action
  async setup() {

        // var _this = this;


    await this.ensureD3();
    const result = await this.fetchData(this.model.topic_id);
    debugger;

      const workflowData = {
        lanes: result.lanes,
        nodes: result.nodes,
        links: result.links
        }
    // lanes: [
    //     { name: "Preparers", link: "https://example.com/preparers" },
    //     { name: "Reviewers", link: "https://example.com/reviewers" },
    //     { name: "Finalisers", link: "https://example.com/finalisers" },
    //     { name: "Approvers", link: "https://example.com/approvers" },
    //     { name: "Completed", link: "https://example.com/completed" }
    // ],
    // nodes: [
    //     { id: 'Step A', lane: 0, active: false },
    //     { id: 'Step B', lane: 1, active: false },
    //     { id: 'Step C', lane: 0, active: true },
    //     { id: 'Step D', lane: 2, active: false },
    //     { id: 'Step E', lane: 3, active: false },
    //     { id: 'Step F', lane: 4, active: false },

    // ],
    // links: [
    //     { source: 'Step A', target: 'Step B', action: 'start' },
    //     { source: 'Step B', target: 'Step A', action: 'reject' },
    //     { source: 'Step B', target: 'Step C', action: 'accept' },
    //     { source: 'Step C', target: 'Step D', action: 'process' },
    //     { source: 'Step D', target: 'Step E', action: 'finalize' },
    //     { source: 'Step E', target: 'Step F', action: 'confirmed' },
    //     { source: 'Step E', target: 'Step C', action: 'reopended' }
    // ]
//};

        // Set up the SVG canvas dimensions
        const width = 950;
        const height = 700;

        const laneHeight = height / workflowData.lanes.length;
        const nodeSpacing = width / (workflowData.nodes.length + 1);
        // debugger;
        // Select the SVG container
      const svg = d3
        .select('#workflow-visualisation')
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        // .call(d3.zoom().on("zoom", function () {
        //     svg.attr("transform", d3.event.transform)
        //  }))

        // svg.append("rect")
        //   .attr("width", "100%")
        //   .attr("height", "100%")
        //   .attr("fill", "pink");

        // Draw swim lanes
        const lanes = svg.selectAll('.lane')
            .data(workflowData.lanes)
            .enter()
            .append('g');

        lanes.append('rect')
            .attr('class', 'lane')
            .attr('x', 0)
            .attr('y', (d, i) => i * laneHeight)
            .attr('width', width)
            .attr('height', laneHeight);

        lanes.append('a')
            .attr('xlink:href', d => d.link)
            .attr('target', '_blank')
            .append('text')
            .attr('class', 'lane-label')
            .attr('x', 10)
            .attr('y', (d, i) => i * laneHeight + laneHeight / 2)
            .text(d => d.name);

        // Define arrow marker
        svg.append('defs').append('marker')
            .attr('id', 'arrowhead')
            .attr('viewBox', '0 -5 10 10')
            .attr('refX', 10)
            .attr('refY', 0)
            .attr('markerWidth', 6)
            .attr('markerHeight', 6)
            .attr('orient', 'auto')
            .append('path')
            .attr('d', 'M0,-5L10,0L0,5')
            .attr('class', 'arrowhead');

        // Add links to the SVG
        const link = svg.append('g')
            .attr('class', 'links')
            .selectAll('path')
            .data(workflowData.links)
            .enter()
            .append('path')
            .attr('class', 'link')
            .attr('marker-end', 'url(#arrowhead)');

        // Add labels to links
        const linkLabels = svg.append('g')
            .attr('class', 'link-labels')
            .selectAll('text')
            .data(workflowData.links)
            .enter()
            .append('text')
            .attr('class', 'link-label')
            .attr('text-anchor', 'middle')
            .text(d => d.action);

        // Add nodes to the SVG
        const node = svg.append('g')
            .attr('class', 'nodes')
            .selectAll('rect')
            .data(workflowData.nodes)
            .enter()
            .append('rect')
            .attr('class', d => d.active ? 'node active' : 'node')
            .attr('fill', d => d.active ? '#ffa500' : '#69b3a2')
            .attr('width', 120)
            .attr('height', 90)
            .attr('rx', 5)
            .attr('ry', 5)
            .attr('x', (d, i) => nodeSpacing * (i + 1) )
            .attr('y', d => d.lane * laneHeight + laneHeight / 2 - 45);

        // Add labels to nodes
        const label = svg.append('g')
            .attr('class', 'labels')
            .selectAll('text')
            .data(workflowData.nodes)
            .enter()
            .append('text')
            .attr('text-anchor', 'middle')
            .attr('x', (d, i) => nodeSpacing * (i + 1) + 60)
            .attr('y', d => d.lane * laneHeight + laneHeight / 2 + 5)
            .text(d => d.id);

        // Update links layout
        link
            .attr('d', d => {
                const sourceIndex = workflowData.nodes.findIndex(node => node.id === d.source);
                const targetIndex = workflowData.nodes.findIndex(node => node.id === d.target);
                const sourceX = nodeSpacing * (sourceIndex + 1);
                const sourceY = workflowData.nodes[sourceIndex].lane * laneHeight + laneHeight / 2;
                const targetX = nodeSpacing * (targetIndex + 1);
                const targetY = workflowData.nodes[targetIndex].lane * laneHeight + laneHeight / 2;

                // Handle returning links
                if (sourceIndex > targetIndex) {
                    const arcHeight = 50 * (sourceIndex - targetIndex); // Adjust arc height dynamically
                    return `M${sourceX},${sourceY} V${sourceY - arcHeight} H${targetX} V${targetY}`;
                }

                return `M${sourceX},${sourceY} H${(sourceX + targetX) / 2} V${targetY} H${targetX}`;
            });

        linkLabels
            .attr('x', d => {
                const sourceIndex = workflowData.nodes.findIndex(node => node.id === d.source);
                const targetIndex = workflowData.nodes.findIndex(node => node.id === d.target);
                const sourceX = nodeSpacing * (sourceIndex + 1);
                const targetX = nodeSpacing * (targetIndex + 1);
                return (sourceX + targetX) / 2;
            })
            .attr('y', d => {
                const sourceIndex = workflowData.nodes.findIndex(node => node.id === d.source);
                const targetIndex = workflowData.nodes.findIndex(node => node.id === d.target);
                const sourceY = workflowData.nodes[sourceIndex].lane * laneHeight + laneHeight / 2;
                const targetY = workflowData.nodes[targetIndex].lane * laneHeight + laneHeight / 2;

                if (sourceIndex > targetIndex) {
                    const arcHeight = 50 * (sourceIndex - targetIndex); // Match arc height for returning links
                    return sourceY - arcHeight / 2;
                }

                return (sourceY + targetY) / 2 - 10;
            });

        // Drag event handlers
        function dragStarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }

        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }

        function dragEnded(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }
      
  }


  <template>
    <DModal
      @title="Workflow Visualisation"
      @closeModal={{@closeModal}}
      class="workflow-visualisation-modal"
      {{didInsert this.setup}}
    >
      <div id="workflow-visualisation"></div>
    </DModal>
  </template>
};
