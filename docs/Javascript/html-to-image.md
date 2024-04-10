## Generate an image from a DOM node (and export/download)

Follow [html-to-image GitHub repo](https://github.com/bubkoo/html-to-image) for install instruction
or get min.js from [cdnjs](https://cdnjs.com/libraries/html-to-image)

E.g. trying to generate and download an image of `div#screenshot-me`:

```html
<div id="screenshot-me">
  <div>
    <img src="https://picsum.photos/id/29/536/354" />
  </div>
  <p>
    Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis
    parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec,
    pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec
    pede justo, fringilla vel, aliquet nec, vulputate eget, arcu.
  </p>
  <p>
    In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam
    dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibus.
    Vivamus elementum semper nisi. Aenean vulputate eleifend tellus. Aenean leo
    ligula, porttitor eu, consequat vitae, eleifend ac, enim. Aliquam lorem
    ante, dapibus in, viverra quis, feugiat a, tellus.
  </p>
  <p>
    Phasellus viverra nulla ut metus varius laoreet. Quisque rutrum. Aenean
    imperdiet. Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies
    nisi. Nam eget dui. Etiam rhoncus. Maecenas tempus, tellus eget condimentum
    rhoncus, sem quam semper libero, sit amet adipiscing sem neque sed ipsum.
    Nam quam nunc, blandit vel, luctus pulvinar, hendrerit id, lorem.
  </p>
</div>

<button
  id="screenshot-btn"
  onclick="takeCardScreenShot('screenshot-me', 'screenshot.png')"
>
  Take a screenshot!
</button>
```

JavaSrcipt to generate the image and trigger download (html-to-image v 1.11.11)

```js
const takeScreenShot = (eleId, filename) => {
  htmlToImage
    .toCanvas(document.getElementById(eleId), {
      quality: 1,
      backgroundColor: "#FFFFFF",
    })
    .then((canvas) => {
      imgSaveAs(canvas.toDataURL("image/png"), `${filename}.png`);
    })
    .catch((error) => {
      console.log(error);
    });
};

const imgSaveAs = (uri, filename) => {
  const link = document.createElement("a");
  if (typeof link.download === "string") {
    link.href = uri;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } else {
    window.open(uri);
  }
};
```
