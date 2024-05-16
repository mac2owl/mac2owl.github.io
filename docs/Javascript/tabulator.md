[Tabulator](https://tabulator.info/)

```js
const initTable = (dataUrl) => {
  const table = new Tabulator("#table", {
    ajaxURL: dataUrl,
    layout: "fitColumns",
    index: "id",
    maxHeight: "50vh",
    resizableColumns: false,
    placeholder: "No Data Available",
    initialSort: [{ column: "timestamp", dir: "desc" }],
    columns: [
      {
        field: "id",
        title: "ID",
        sorter: "string",
        visible: false,
      },
      {
        field: "timestamp",
        title: "Timestamp",
        sorter: "datetime",
        formatter: "datetime",
        formatterParams: {
          inputFormat: "yyyy-MM-dd HH:mm:ss",
          outputFormat: "yyyy-MM-dd HH:mm:ss",
        },
        headerFilter: false,
      },

      {
        field: "date_val",
        title: "Date value",
        sorter: "date",
        sorterParams: {
          alignEmptyValues: "bottom",
          format: "yyyy-MM-dd",
        },
        formatter: "date",
        formatterParams: {
          inputFormat: "yyyy-MM-dd",
          outputFormat: "yyyy-MM-dd",
        },
        headerFilter: true,
      },
      {
        field: "boolean_val",
        title: "Boolean value",
        sorter: "boolean",
        formatter: "tickCross",
        headerFilter: "tickCross",
        headerFilterParams: { tristate: true },
        hozAlign: "center",
        formatterParams: {
          allowEmpty: true,
          allowTruthy: true,
          tickElement: "Yes",
          crossElement: false,
        },
      },
      {
        field: "icon",
        title: "Icon",
        headerFilter: false,
        hozAlign: "center",
        formatter: iconLink,
      },
    ],
  });
};

const iconLink = (cell, formatterParams) => {
  const val = cell.getValue();
  if (!!val) {
    return `<i class="fe fe-link pointer" data-bs-toggle="tooltip" data-bs-placement="top" title="${val}"></i>`;
  }
  return "";
};

const refreshTableDate = (dataUrl) => {
  table.replaceData(dataUrl);
};
```
