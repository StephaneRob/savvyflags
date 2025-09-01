import uPlot from 'uplot'

export default {
  mounted() {
    const opts = {
      width: this.el.clientWidth,
      height: 300,
      scales: {
        x: {
          time: true,
        },
      },
      axes: [
        {
          values: (u, vals) => vals.map(v => new Date(v * 1000).toLocaleDateString()),
        },
      ],
      series: [
        {},
        {
          stroke: '#00d492',
          fill: '#d0fae5',
        },
      ],
    }

    const data = JSON.parse(this.el.querySelector('div#data').dataset.data)
    this.chart = new uPlot(opts, data, this.el.querySelector('div#chart'))
  },

  updated() {
    this.chart.setData(JSON.parse(this.el.querySelector('div#data').dataset.data))
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy()
    }
  },
}
