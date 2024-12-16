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

## Download blob/file with fetch

```js
const downloadFile = (fileUrl) => {
  fetch(fileUrl, {
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  })
    .then((response) => {
      if (!response.ok) {
        return response.json().then((body) => {
          // error handling
          if (body.status == "error") {
            return downloadErrorHandler();
          }
          throw new Error("HTTP status " + response.status);
        });
      }
      return response.blob().then((blob) => {
        filename = extractFilenameFromHeaders(response.headers);
        return downloadBlob(blob, filename);
      });
    })
    .catch((error) => {
      console.log(error);
    });
};

const downloadBlob = (blob, filename) => {
  const link = document.createElement("a");
  link.href = window.URL.createObjectURL(blob);
  link.download = filename;
  link.click();
  link.remove();
};

// Extract filename from headers
const extractFilenameFromHeaders = (headers) => {
  const header = headers.get("Content-Disposition");
  const parts = header.split(";");
  return parts[1].split("=")[1];
};
```

## Open url on same tab

```
window.location.href = url;
```

## Open url on new tab

```
window.open(url, "_blank");
```

# Axios

[Axios](https://axios-http.com/)
