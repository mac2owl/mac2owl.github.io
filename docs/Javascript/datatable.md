## Reload table(s) with new data

```js
const reloadDatableData = () => {
  const dataUrl = `/data-api-endpoint`;

  fetch(dataUrl)
    .then((response) => response.json())
    .then((data) => {
      const datatable = $("#datatable-id").DataTable();
      datatable.clear().rows.add(data).draw();
      // in case of table width not working properly (responsive)
      setTimeout(function () {
        $("#datatable-id").DataTable().columns.adjust().draw();
      }, 100);
    });
};
```

## Rezise table(s) to fit container in bootstrap (v5) tabs

```js
const initTabsEvts = () => {
  const tabEl = document.querySelectorAll('a[data-bs-toggle="tab"]');
  tabEl.forEach((ele) => {
    ele.addEventListener("shown.bs.tab", function (event) {
      const datatables = document.querySelector(".tab-pane.active .datatable");
      datatables.forEach((datatable) => {
        setTimeout(function () {
          $(datatable).DataTable().columns.adjust().draw();
        }, 50);
      });
    });
  });
};
```
