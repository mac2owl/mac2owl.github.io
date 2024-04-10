## Plotly JS

Placeholder for chart in HTML:

```html
<div id="chart-id-here" class="plotly-charts"></div>

initChart("chart-id-here");
```

Javascript to fetch chart data from API endpoint

```js
const initChart = (eleId) => {
  fetch("/api-endpoint-for-chart-data")
    .then((response) => response.json())
    .then((data) => {
      const chartData = data.chart_data;
      const plotConfigData = data.config_data;
      plotlyChart(eleId, chartData, null, plotConfigData);
    });
};
```

```js
const plotlyChartLayout = (title, opts) => {
  let layout = $.extend(
    {
      title: {
        text: title,
        font: {
          size: 12,
        },
      },
      xaxis: {
        tickfont: {
          size: 11,
        },
      },
      yaxis: {
        automargin: true,
        tickfont: {
          size: 11,
        },
      },
      showlegend: true,
      legend: {
        font: {
          size: 10,
        },
      },
      bargap: 0.2,
      font: { color: "#4e4e4e" },
    },
    opts
  );

  return layout;
};

const plotlyChart = (
  targetEle,
  data,
  title,
  opts = null,
  configOpts = null,
  refreshData = false
) => {
  const layout = plotlyChartLayout(title, opts);
  const imgFilename = opts.filename ? opts.filename : "plot-image";
  const config = $.extend(
    {
      responsive: true,
      displayModeBar: true,
      // to hide the buttons/chart functions we don't want
      modeBarButtonsToRemove: [
        "zoom2d",
        "pan2d",
        "select2d",
        "lasso2d",
        "zoomIn2d",
        "zoomOut2d",
        "autoScale2d",
        "resetScale2d",
      ],
      toImageButtonOptions: {
        format: "png",
        filename: imgFilename,
        scale: 2,
      },
      displaylogo: false,
    },
    configOpts
  );
  if (refreshData) {
    Plotly.react(targetEle, data, layout, config);
  } else {
    Plotly.newPlot(targetEle, data, layout, config);
  }
};
```

## Rezise chart(s) to fit container in bootstrap (v5) tabs

```js
const initTabsEvts = () => {
  const tabEl = document.querySelectorAll('a[data-bs-toggle="tab"]');
  tabEl.forEach((ele) => {
    ele.addEventListener("shown.bs.tab", function (event) {
      const charts = document.querySelectorAll(
        ".tab-pane.active .plotly-charts"
      );
      charts.forEach((chart) => {
        Plotly.relayout(chart, { autosize: true });
      });
    });
  });
};
```
