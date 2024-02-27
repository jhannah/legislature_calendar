
// Robert Penner’s "Flash easing functions"
function getEase(currentProgress, start, distance, steps, power) {
  currentProgress /= steps/2;
  if (currentProgress < 1) {
    return (distance/2)*(Math.pow(currentProgress, power)) + start;
  } 
  currentProgress -= 2;
  return distance/2*(Math.pow(currentProgress,power)+2) + start;
}

function getX(params) {
  let distance = params.xTo - params.xFrom;
  let steps = params.frames;
  let currentProgress = params.frame;
  return getEase(currentProgress, params.xFrom, distance, steps, 3);
}

function getY(params) {
  let distance = params.yTo - params.yFrom;
  let steps = params.frames;
  let currentProgress = params.frame;
  return getEase(currentProgress, params.yFrom, distance, steps, 3);
}

function addBill(params) {
  let name = params.name;
  billCtx.fillStyle = "blue";
  billCtx.clearRect(getX(params) -1, getY(params) -1, billWidth + 2, billWidth + 2);
  console.debug("you drew a rect");
  if (params.frame < params.frames) {
    params.frame = params.frame + 1;
    window.requestAnimationFrame(addBill.bind(null, params))
  }
  billCtx.fillRect(getX(params), getY(params), billWidth, billWidth);
}

function drawCanvas() {
  billCtx.clearRect(0, 0, canvasWidth, canvasHeight);
  //billCtx.fillStyle = 'rgb(255,255,255)';
  //billCtx.fillRect(0, 0, billCanvas.width, billCanvas.height);
}

function play() {
  drawCanvas();
  addBill({
    name: 'LB1',
    frame: 0,
    frames: 100,
    xFrom: 10,
    xTo: 290,
    yFrom: 10,
    yTo: 290
  });
  addBill({
    name: 'LB2',
    frame: 0,
    frames: 100,
    xFrom: 150,
    xTo: 70,
    yFrom: 50,
    yTo: 200
  });
}