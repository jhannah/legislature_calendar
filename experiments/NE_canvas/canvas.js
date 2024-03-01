var backgroundCanvas, billCanvas;
var backgroundCtx, billCtx;
var committees, dates;
var canvasWidth, canvasHeight;
var billWidth = 4;

function setupGlobals(document) {
  // Starting point: https://css-tricks.com/easing-animations-in-canvas/
  backgroundCanvas = document.getElementById('backgroundCanvas');
  // console.log(backgroundCanvas);

  canvasWidth = backgroundCanvas.width;
  canvasHeight = backgroundCanvas.height;
  // console.log("width " + canvasWidth + " height " + canvasHeight)
  backgroundCtx = backgroundCanvas.getContext('2d');
  billCanvas = document.getElementById('billCanvas');
  billCtx = billCanvas.getContext('2d');
  backgroundCtx.font = "14px sanserif";
  // backgroundCtx.fillText("Introduced", 5, 20);
}

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
  //console.log("you drew a rect");
  if (params.frame < params.frames) {
    params.frame = params.frame + 1;
    //console.log("requesting " + params.name + " frame " + params.frame)
    //console.log("requesting frame " + params.frame)
    window.requestAnimationFrame(addBill.bind(null, params))
  }
  billCtx.fillRect(getX(params), getY(params), billWidth, billWidth);
}

function drawCanvas() {
  billCtx.clearRect(0, 0, canvasWidth, canvasHeight);
  backgroundCtx.clearRect(0, 0, canvasWidth, canvasHeight);
  //billCtx.fillStyle = 'rgb(255,255,255)';
  //billCtx.fillRect(0, 0, billCanvas.width, billCanvas.height);
  for (c of committees) {
    backgroundCtx.fillText(c.name, c.x, c.y);
  }
}

function play_again() {
  play(committees, dates);
}

function play(c, d) {
  committees = c;
  dates = d;
  for (const d in dates) {
    console.log("uhhh date " + d + " exists")
  }
  //console.log("dates is " + dates)
  //for (const date in Object.keys(dates)) {
  forEachSeries(dates, myPromise)
}

// https://stackoverflow.com/questions/43082934/how-to-execute-promises-sequentially-passing-the-parameters-from-an-array
const forEachSeries = async (iterable, action) => {
  for (const x in iterable) {
    await action(x);
  }
}

function myPromise(date) {
  return new Promise(res => {
    play_date(date);
  });
}

function play_date(date) {
  console.log("play_date(" + date + ")");
  drawCanvas();
  // var cnt = 0;
  movements = dates[date]["movements"];
  //console.log(typeof(movements));
  for (const number in movements) {
    coords = movements[number];
    // console.log("  " + number + " " + coords.xFrom);
    addBill({
      name: number,
      frame: 0,
      frames: 100,
      xFrom: coords.xFrom,
      xTo: coords.xTo,
      yFrom: coords.yFrom,
      yTo: coords.yTo
    });
    // cnt += 1;
    // if (cnt == 20) {
    //   break;   // abort, that's enough dates
    // }
  }
  console.log("all addBill() calls complete");
  return 1;
}
