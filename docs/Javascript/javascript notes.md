## Copy to clipboard

```js
const copyToClipboard = (txt) => {
  try {
    navigator.clipboard.writeText(url);
  } catch (e) {
    unsecuredCopyToClipboard(txt);
  }
  showToastNotification("Copied to clipboard", "success");
};

const unsecuredCopyToClipboard = (text) => {
  const ta = document.createElement("textarea");
  ta.value = text;
  document.body.appendChild(ta);
  ta.focus();
  ta.select();
  try {
    document.execCommand("copy");
  } catch (err) {
    console.error("Unable to copy to clipboard", err);
  }
  document.body.removeChild(ta);
};
```

## fetch

```js
const fetchExample = (url) => {
  fetch(url, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ ... }),
  })
    .then((res) => {
      if (res.ok) {
        return res.json();
      }
      return Promise.reject(res);
    })
    .then((body) => {
      ...
    })
    .catch((error) => {
      ...
    })
    .finally(() => {
     ...
    });
};
```

# Axios

(Axios)[https://axios-http.com/]
