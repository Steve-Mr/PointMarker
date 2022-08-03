<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Created by IntelliJ IDEA.
  User: maary
  Date: 2022/6/30
  Time: 上午11:30
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>

  <title>Map</title>

  <meta charset="utf-8"/>

  <script type="text/javascript" src="https://static.robotwebtools.org/EaselJS/current/easeljs.min.js"></script>
  <script type="text/javascript"
          src="https://static.robotwebtools.org/EventEmitter2/current/eventemitter2.min.js"></script>
  <script type="text/javascript" src="https://static.robotwebtools.org/roslibjs/current/roslib.min.js"></script>
  <script type="text/javascript" src="https://static.robotwebtools.org/ros2djs/current/ros2d.min.js"></script>

  <script type="text/javascript">

    let SERVER_ADDRESS = "http://:8080";
    let URL_SENDOBJ = SERVER_ADDRESS + "/gs-robot/cmd/update_virtual_obstacles?";

    function init() {
      console.log("init...");

      /**
       * request 中参数：
       * status: 数据获取是否成功，失败则返回前一页
       * url: 地图的图片链接
       * resolution, originX, originY: 同地图定义
       * json: 获取到的障碍物数据
       * */
      let originX = 0;
      let originY = 0;

      // 数据获取有问题，回到上一页
      if (!${requestScope.status}){
        alert("error occurred");
        history.back();
        return;
      }

      originX = ${requestScope.originX};
      originY = ${requestScope.originY};

      let canvas = document.getElementById("map");    // 展示地图
      let stage = new createjs.Stage(canvas);
      let table = document.getElementById("ptable"); // 障碍物表格

      let bitmap = new createjs.Bitmap("${requestScope.url}");
      bitmap.scaleX = ${requestScope.resolution};
      bitmap.scaleY = ${requestScope.resolution};

      /**
       * 这里由于 polygon 有多重意义容易产生混淆
       * 故作出说明
       * 当 polygon 为障碍物的形状，即「多边形」意时，则称为「多边形」
       * 当 polygon 为绘制各种形状的工具时，则称为「容器」/polygon
       * */
      // 标记 多边形/折线 时需要一个结束标志
      // buttonDrawNew: 结束当前图形绘制，开始下一个
      // buttonFinishCurrent： 结束当前图形绘制
      let buttonDrawNew = document.getElementById("newObj");
      let buttonFinishCurrent = document.getElementById("finishObj");
      // 提交结果按钮
      let buttonSubmit = document.getElementById("submitPoints");

      // 用来记录类型和形状的状态，避免在绘制 多边形/折线 时因切换种类/形状造成记录错误
      let preType, preShape;

      // 缩放视图
      let zoomView = new ROS2D.ZoomView({
        rootObject: stage
      });
      // 平移视图
      let panView = new ROS2D.PanView({
        rootObject: stage
      });

      // 鼠标点击容器时的回调函数
      let clickedPolygon = false;
      let selectedPointIndex = null;

      // 记录在标记 圆 且没有设置半径时第一次点击坐标
      let isRadiusUnsetClicked = false;
      let circlePos;

      let objList = [];   // 所有障碍物对象列表
      // 线段/方形/多边形/折线 需要记录点列表
      let linesPos = [];
      let rectPos = [];
      let polyPos = [];

      let pointCallBack = function (type, event, index) {
        if (type === 'mousedown') {
            selectedPointIndex = index;
        }
        clickedPolygon = true;
      };

      let lineCallBack = function (type, event, index) {
      }

      // 不同形状在地图上对应不同的颜色
      let colorMap = new Map([
        ["carpets", createjs.Graphics.getRGB(176, 219, 67, 1)],
        ["decelerations", createjs.Graphics.getRGB(18, 234, 234, 1)],
        ["displays", createjs.Graphics.getRGB(188, 231, 253, 1)],
        ["highlight", createjs.Graphics.getRGB(196, 146, 177, 1)],
        ["obstacles", createjs.Graphics.getRGB(219, 39, 99, 1)],
        ["slopes", createjs.Graphics.getRGB(240, 247, 87, 1)]
      ]);

      // 地图代表物理区域大小，单位为米，即地图图片大小 * 比例
      let bitmapW;
      let bitmapH;
      // 创建 容器，用于显示标记点和将标记点连接——即线段
      let polygon = createPolygon();
      // 等待地图图像的加载，避免由于加载速度问题导致显示异常
      bitmap.image.onload = function () {

        bitmapW = bitmap.image.width * ${requestScope.resolution};
        bitmapH = bitmap.image.height * ${requestScope.resolution};

        // 根据地图比例修改 canvas 比例
        if (bitmapW < bitmapH){
          canvas.setAttribute("height", Math.round(bitmapH/bitmapW * canvas.getAttribute("width")).toString());
        }else {
          canvas.setAttribute("width", Math.round(bitmapW/bitmapH * canvas.getAttribute("height")).toString());
        }

        // 设置 stage 的缩放比例
        // 清除旧比例（如果存在）
        stage.x = typeof stage.x_prev_shift !== 'undefined' ? stage.x_prev_shift : stage.x;
        stage.y = typeof stage.y_prev_shift !== 'undefined' ? stage.y_prev_shift : stage.y;

        // 设置 stage 缩放比例
        stage.scaleX = canvas.getAttribute("width") / bitmapW;
        stage.scaleY = canvas.getAttribute("height") / bitmapH;

        // stage 添加地图对象，先添加的位于底部
        stage.addChild(bitmap);

        // stage 自动刷新
        createjs.Ticker.framerate = 30;
        createjs.Ticker.addEventListener("tick", stage);
        stage.update();

        // Event listeners for mouse interaction with the stage
        stage.mouseMoveOutside = false; // doesn't seem to work

        // 加载预置障碍物
        loadMapObj();
      }

      // 选择标记点的类型，只有在选择后才能进行点的标记
      // 障碍物类型 radio buttons
      let radios = document.querySelectorAll('input[name="objType"]');
      // 障碍物形状 radio buttons
      let shapeRadios = document.querySelectorAll('input[name="shapeType"]');
      let key;
      for (const radio of radios) {
        radio.addEventListener("change", function () {
          // 根据障碍物类型设置 容器 的颜色
          let color = colorMap.get(radio.value);
          polygon.pointColor = color;
          polygon.lineColor = color;
          polygon.fillColor = color;

          // 清除 stage event listener 避免添加重复 listener
          stage.removeAllEventListeners();
          for (let shapeRadio of shapeRadios){
            // 选择障碍物类型后重置形状 radio buttons 的状态
            shapeRadio.checked = false;
            shapeRadio.disabled = false;

            shapeRadio.addEventListener("change", function () {
              key = shapeRadio.value;
              // 若更改状态时有仍未保存的已标记障碍物先进行保存
              archiveExistedPoly();
              preType = radio.value;

              stage.removeAllEventListeners();
              registerMouseHandlers();
              addNewPolygon();

              // 无关按钮需要隐藏
              buttonDrawNew.disabled = true;
              buttonDrawNew.hidden = true;
              buttonFinishCurrent.disabled = true;
              buttonFinishCurrent.hidden = true;

              // 形状选择 折线 需要形状将内部填充颜色设置为透明
              if (shapeRadio.value === "polylines")
                polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);
              preShape = shapeRadio.value;
            })
          }
        })
      }

      // 将尚未保存的已标记 多边形 或 折线 加入列表
      // 若 preType 和 preShape 值存在则使用相应值
      function archiveExistedPoly() {
        if (polyPos.length !== 0){
          addToObjList({
            type: preType? preType : document.querySelector('input[name="objType"]:checked').value,
            shape: preShape? preShape : document.querySelector('input[name="shapeType"]:checked').value,
            points: polyPos
          });

          createNo(objList);
          polyPos = [];
        }
      }

      function registerMouseHandlers() {
        // 处理鼠标操作
        // 单击添加点
        // 按住 ctrl 点击不放拖动鼠标： 缩放地图
        // 按住 shift 点击不放拖动鼠标： 移动地图（可能会和移除点冲突）
        let mouseDown = false;
        let zoomKey = false;
        let panKey = false;
        let startPos = new ROSLIB.Vector3();

        stage.addEventListener('stagemousedown', function (event) {
          if (event.nativeEvent.ctrlKey === true) {
            zoomKey = true;
            zoomView.startZoom(event.stageX, event.stageY);
          }
          else if (event.nativeEvent.shiftKey === true) {
            panKey = true;
            panView.startPan(event.stageX, event.stageY);
          }
          startPos.x = event.stageX;
          startPos.y = event.stageY;
          mouseDown = true;
        });

        stage.addEventListener('stagemousemove', function (event) {
          if (mouseDown === true) {
            if (zoomKey === true) {
              let dy = event.stageY - startPos.y;
              let zoom = 1 + 10 * Math.abs(dy) / stage.canvas.clientHeight;
              if (dy < 0)
                zoom = 1 / zoom;
              zoomView.zoom(zoom);
            }
            else if (panKey === true) {
              panView.pan(event.stageX, event.stageY);
            }
          }
        });

        stage.addEventListener('stagemouseup', function (event) {
          if (mouseDown === true) {
            if (zoomKey === true) {
              zoomKey = false;
            }
            else if (panKey === true) {
              panKey = false;
            }
            else {
              // Add point when not clicked on the polygon
              if (selectedPointIndex !== null) {
                selectedPointIndex = null;
              }
              else if (stage.mouseInBounds === true && clickedPolygon === false) {
                let pos = stage.globalToRos(event.stageX, event.stageY);

                switch (key){
                  case "circles":
                    // 添加 circles：
                    // 首先记录点击位置，并显示半径的输入框和确认按钮
                    // 记录首次点击位置后则屏蔽所有点击 stage 的动作
                    //    通过 isRadiusUnsetClicked 实现，即「是否已在未设置半径下进行了点击」
                    //        true：已经记录过坐标，屏蔽点击 false：尚未点击，记录坐标
                    // 输入坐标后点击「确定」按钮则添加圆
                    let radiusBox = document.getElementById("radiusBox");
                    let buttonSave = document.getElementById("saveRadius");
                    radiusBox.addEventListener('input', updatePoint);
                    buttonSave.addEventListener("click", createCircle);
                    let prePointSize = polygon.pointSize;

                    if(!isRadiusUnsetClicked){
                      circlePos = pos;
                      if (polygon.pointContainer.getNumChildren() !== 0){
                        addNewPolygon();
                      }
                      polygon.addPoint(pos);

                      radiusBox.hidden = false;
                      radiusBox.value = "";
                      buttonSave.hidden = false;
                      buttonSave.disabled = true;

                      isRadiusUnsetClicked = true;
                    }

                    function updatePoint() {
                      buttonSave.disabled = radiusBox.value.length === 0;
                    }

                  function createCircle() {
                    polygon.remPoint(polygon.pointContainer.getNumChildren() -1);

                    polygon.pointSize = parseFloat(radiusBox.value) === 0 ? prePointSize :  parseFloat(radiusBox.value) * 2;
                    radiusBox.hidden = true;
                    buttonSave.hidden = true;

                    if (!isRadiusUnsetClicked) {
                      pos = circlePos;
                    }
                    polygon.addPoint(pos);
                    polygon.pointSize = prePointSize;

                    addToObjList({
                      type: document.querySelector('input[name="objType"]:checked').value,
                      shape: document.querySelector('input[name="shapeType"]:checked').value,
                      points: [pos],
                      radius: radiusBox.value
                    })

                    createNo(objList);

                    isRadiusUnsetClicked = false;

                    buttonSave.removeEventListener("click",createCircle);
                    radiusBox.removeEventListener("input", updatePoint);
                  }

                    break;
                  case "lines":
                    // 添加 lines：
                    // 每有两个点（即一条线）则添加到障碍物列表（objList）一次
                    // 已经添加过两个点再点击则添加新的容器
                    if (polygon.pointContainer.getNumChildren() !== 2){
                      linesPos.push(pos);
                      polygon.addPoint(pos);

                      if (polygon.pointContainer.getNumChildren() === 2){
                        addToObjList({
                          type: document.querySelector('input[name="objType"]:checked').value,
                          shape: document.querySelector('input[name="shapeType"]:checked').value,
                          points: linesPos,
                        })

                        createNo(objList);

                        linesPos = [];
                      }
                    } else {
                      addNewPolygon();
                      linesPos.push(pos);
                      polygon.addPoint(pos);
                    }
                    break;
                  case "polygons":
                    // 点击则添加点，通过 buttonDrawNew/buttonFinishCurrent 结束
                    buttonDrawNew.hidden = false;
                    buttonFinishCurrent.hidden = false;
                    polygon.addPoint(pos);
                    polyPos.push(pos);
                    buttonDrawNew.disabled = false;
                    buttonDrawNew.addEventListener('click', updateObj);
                    buttonFinishCurrent.disabled = false;
                    buttonFinishCurrent.addEventListener('click', finishObj)
                    break;
                  case "polylines":
                    // 为了实现折线效果，每次添加点都需要删除之前的点重新进行绘制并移除最后一个点和起始点之间的连线
                    buttonDrawNew.hidden = false;
                    buttonFinishCurrent.hidden = false;

                    polyPos.push(pos);
                    buttonDrawNew.disabled = false;
                    buttonDrawNew.addEventListener('click', updateObj);
                    buttonFinishCurrent.disabled = false;
                    buttonFinishCurrent.addEventListener('click', finishObj)

                    polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);
                    if (polygon.pointContainer.getNumChildren() >= 2){
                      polygon.pointContainer.removeAllChildren();
                      polygon.lineContainer.removeAllChildren();
                      polygon.drawFill();
                      for (let i = 0; i < polyPos.length; i++){
                        polygon.addPoint(polyPos[i]);
                      }
                      polygon.lineContainer.removeChildAt(polygon.lineContainer.getNumChildren() -1);
                    }else{
                      polygon.addPoint(pos);
                    }
                    break;
                  case "rectangles":
                    // 每添加两个点则构成一个方形并添加到障碍物列表，然后添加新的容器
                    let x1, x2, y1, y2;

                    if (polygon.pointContainer.getNumChildren() === 0){
                      polygon.addPoint(pos);
                      rectPos.push(pos);
                    } else if (polygon.pointContainer.getNumChildren() === 1){
                      x1 = polygon.pointContainer.getChildAt(0).x;
                      y1 = -polygon.pointContainer.getChildAt(0).y;
                      x2 = pos.x;
                      y2 = pos.y;
                      polygon.addPoint({x:x1, y:y2, z:0});
                      polygon.addPoint({x:x2, y:y2, z:0});
                      polygon.addPoint({x:x2, y:y1, z:0});

                      rectPos.push({x:x2, y:y2, z:0});

                      addToObjList({
                        type: document.querySelector('input[name="objType"]:checked').value,
                        shape: document.querySelector('input[name="shapeType"]:checked').value,
                        points: rectPos
                      });

                      createNo(objList);

                      rectPos = [];

                      addNewPolygon();
                    }
                    break;
                  default:
                    break;
                }
              }
              clickedPolygon = false;
            }
            mouseDown = false;
          }
        });
      }

      // 由于坐标系位置不一致需要对点坐标进行换算
      // x：只需要计算 originX 并四舍五入
      // y：pos 坐标系原点为左上角，需要的坐标系原点为左下角，需要将 pos.y 值和 bitmapH 相加
      function getDisplayCoord(pos){
        this.pos = pos;
        return {
          x : Math.round(this.pos.x - originX),
          y : Math.round(this.pos.y+bitmapH-originY)};
      }

      // 根据 json 中符合地图坐标系的坐标转换为可以在 stage 上添加的坐标
      function getOnStageCoord(obj){
        return {
          x: obj.x + originX,
          y: obj.y + originY - bitmapH
        };
      }

      // 生成返回服务器的 JSON 字符串，格式参照 1.7.1 生成手画路径部分。
      function generateResultJSON() {

        let result = {
                  "carpets": {"circles": [],"lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "carpetsWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "decelerations": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "decelerationsWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "displays": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "displaysWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "highlight": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "highlightWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "obstacles": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "obstaclesWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "slopes": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []},
                  "slopesWorld": {"circles": [], "lines": [], "polygons": [], "polylines": [], "rectangles": []}
                };

        // 障碍物列表空，则返回空结果
        if (objList.length === 0){
          console.log(JSON.stringify(result));
          return JSON.stringify(result);
        }
        
        for (let obj of objList){
          result[obj.type] = addToResult(result[obj.type], obj);
        }

        // 根据 类型/形状 将对象添加到对应列表中
        function addToResult(type ,obj) {
          for (let i = 0; i < obj.points.length; i++){
            obj.points[i] = getDisplayCoord(obj.points[i]);
          }
          let points = [];
          switch (obj.shape) {
            case "circles":
              type.circles.push({
                x: obj.points[0].x,
                y: obj.points[0].y,
                r: obj.radius
              });
              break;
            case "lines":
            case "rectangles":
              type[obj.shape].push(
                      [
                        {
                          x: obj.points[0].x,
                          y: obj.points[0].y
                        },
                        {
                          x: obj.points[1].x,
                          y: obj.points[1].y
                        }]
              )
              break;
            case "polygons":
            case "polylines":
              for(let point of obj.points){
                points.push({
                  x: point.x,
                  y: point.y
                })
              }
              type[obj.shape].push(points);
              points = [];
              break;
            default:
              break;
          }
          return type;
        }
        console.log(JSON.stringify(result));

        return JSON.stringify(result);
      }

      // 点击提交按钮向服务器提交信息
      (function() {
        let httpRequest;
        buttonSubmit.addEventListener('click', makeRequest);

        function makeRequest() {
          archiveExistedPoly();

          httpRequest = new XMLHttpRequest();

          let url = URL_SENDOBJ + "map_name=" + "${requestScope.name}" + "&obstacle_name="

          if (!httpRequest) {
            alert('Giving up :( Cannot create an XML HTTP instance');
            return false;
          }
          httpRequest.onreadystatechange = alertContents;
          console.log("url", url)
          httpRequest.open('POST', url);
          httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
          httpRequest.send(generateResultJSON());

          console.log(httpRequest);
        }

        function alertContents() {
          if (httpRequest.readyState === XMLHttpRequest.DONE) {
            let resJSON = JSON.parse(httpRequest.responseText);
            if (resJSON.msg !== "successed"){
              alert("update obstacles failed");
            }
          }
        }

      })();

      // 创建容器
      function createPolygon(color){
        return new ROS2D.PolygonMarker({
          pointColor: color,
          lineColor: color,
          pointCallBack: pointCallBack,
          lineCallBack: lineCallBack,
          pointSize: bitmapW? bitmapW * 0.01 * 0.5 : 1,
          lineSize: bitmapW? bitmapW * 0.01 * 0.5 : 1,
          fillColor: color
        });
      }

      // 加载各种地图上的特殊对象
      function loadMapObj() {
        let mapObjs = ${requestScope.mapObj};
        console.log(JSON.stringify(mapObjs));

        let obj;
        for (let key in mapObjs){
          if (key.includes("World")) continue;
          obj = mapObjs[key];
          for (let shape in obj){
            drawObj(shape, obj[shape], key);
          }
        }
      }

      // 根据坐标等参数在地图上绘制特殊对象
      function drawObj(objShape, obj, type) {
        switch (objShape.toString()) {
          case "circles":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(colorMap.get(type));
              polygon.pointSize = obj[i].r;
              let convertedPoint = getOnStageCoord(obj[i]);
              let pos = {
                x: convertedPoint.x,
                y: convertedPoint.y,
                z: 0};
              polygon.addPoint(pos);
              polygon.lineContainer.removeAllChildren();
              stage.addChild(polygon);

              addToObjList({
                type: type,
                shape: objShape,
                points: [pos],
                radius: obj[i].r
              })

              createNo(objList);
            }
            break;
          case "lines":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(colorMap.get(type));
              let points = [];
              for (let j = 0; j < obj[i].length; j++){
                let convertedPoint = getOnStageCoord(obj[i][j]);
                let pos = {
                  x: convertedPoint.x,
                  y: convertedPoint.y,
                  z: 0};
                polygon.addPoint(pos);
                points.push(pos);
              }
              stage.addChild(polygon);

              addToObjList({
                type: type,
                shape: objShape,
                points: points
              })

              createNo(objList);

            }
            break;
          case "polygons":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(colorMap.get(type))
              let points = [];
              for (let j = 0; j < obj[i].length; j++){
                let convertedPoint = getOnStageCoord(obj[i][j]);
                let pos = {
                  x: convertedPoint.x,
                  y: convertedPoint.y,
                  z: 0};
                polygon.addPoint(pos);
                points.push(pos);
              }
              stage.addChild(polygon);

              addToObjList({
                type: type,
                shape: objShape,
                points: points
              })

              createNo(objList);
            }
            break;
          case "polylines":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(colorMap.get(type));
              polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);

              let points = [];

              for (let j = 0; j < obj[i].length; j++){
                let convertedPoint = getOnStageCoord(obj[i][j]);
                let pos = {
                  x: convertedPoint.x,
                  y: convertedPoint.y,
                  z: 0};
                polygon.addPoint(pos);
                points.push(pos);
              }
              if (obj[i].length >= 3){
                polygon.lineContainer.removeChildAt(obj[i].length - 1);
              }

              addToObjList({
                type: type,
                shape: objShape,
                points: points
              })

              stage.addChild(polygon);

              createNo(objList);

            }
            break;
          case "rectangles":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(colorMap.get(type));
              let convertedPoint1 = getOnStageCoord(obj[i][0]);
              let convertedPoint2 = getOnStageCoord(obj[i][1]);
              let x1 = convertedPoint1.x;
              let y1 = convertedPoint1.y;
              let x2 = convertedPoint2.x;
              let y2 = convertedPoint2.y;
              polygon.addPoint({x:x1, y:y1, z:0});
              polygon.addPoint({x:x1, y:y2, z:0});
              polygon.addPoint({x:x2, y:y2, z:0});
              polygon.addPoint({x:x2, y:y1, z:0});
              addToObjList({
                type: type,
                shape: objShape,
                points: [{x:x1, y:y1, z:0}, {x:x2, y:y2, z:0}]
              })
              stage.addChild(polygon);

              createNo(objList);

            }
            break;
          default:
            break;
        }
        stage.update();
      }

      // 创建新的容器并添加到 stage
      function addNewPolygon() {
        polygon = createPolygon(
                colorMap.get(document.querySelector('input[name="objType"]:checked').value)
        );
        stage.addChild(polygon);

        stage.update();
        polyPos = [];
      }

      // buttonNewObj 功能
      function updateObj() {
        archiveExistedPoly();
        addNewPolygon();
        polyPos = [];
        buttonDrawNew.disabled = true;
        buttonDrawNew.removeEventListener("click", updateObj);
      }

      // buttonFinishObj 功能
      function finishObj(){
        archiveExistedPoly();
        polyPos = [];
        buttonFinishCurrent.disabled = true;
        buttonDrawNew.disabled = true;
        buttonFinishCurrent.removeEventListener("click", finishObj);
        buttonDrawNew.removeEventListener("click", updateObj);

        buttonFinishCurrent.hidden = true;
        buttonDrawNew.hidden = true;

        // 重置两排 radio button 状态
        for (let radio of radios){
          radio.checked = false;
          radio.disabled = false;
        }

        for (let shapeRadio of shapeRadios){
          shapeRadio.checked = false;
          shapeRadio.disabled = true;
        }

        stage.removeAllEventListeners();
      }

      function addToObjList(options) {
        this.type = options.type;
        this.shape = options.shape;
        this.points = options.points;
        this.radius = options.radius || 0;

        // 在屏幕上输出信息
        table.hidden = false;
        let tr = table.insertRow(table.rows.length);
        let cell4 = tr.insertCell(0);
        let cell0 = tr.insertCell(1);
        let cell1 = tr.insertCell(2);
        let cell2 = tr.insertCell(3);
        let cell3 = tr.insertCell(4);

        // 在表格中显示序号
        cell4.innerText = cell4.parentNode.rowIndex - 1;

        cell0.innerText = this.type;
        cell1.innerText = this.shape;
        cell2.innerText = getXY(this.points, this.radius);
        let button;
        if (cell3.childNodes.length !== 0){
          button = cell3.childNodes[0];
        }else{
          button = document.createElement("button");
          button.innerText = "delete";
          cell3.appendChild(button);
          button.addEventListener("click", deleteRow);
        }

        objList.push({
          type: this.type,
          shape: this.shape,
          points: this.points,
          radius: this.radius,
        });

        // 根据 pos 坐标（x, y, z） 得到 x, y 坐标
        function getXY(points, radius) {
          let pointString = "";
          for (let point of points){
            point = getDisplayCoord(point);
            if (radius === 0){
              pointString += " {x: "+ point.x + ", y: " + point.y + "}";
            }else{
              pointString += " {x: "+ point.x + ", y: " + point.y + ", r: " + radius +"}";
            }
          }
          return pointString;
        }

        function deleteRow() {
          clearStage();

          // 在删除表中对应行的同时删除 stage 中对应容器
          let index = button.parentNode.parentNode.rowIndex -1;
          stage.removeChildAt(index * 2 + 1, index * 2 + 2); // 其中 stage 的第一个子对象是 bitmap 即地图
          // 添加了序号后，障碍物和对应序号对象为一组，每次删除时直接删除一组。
          // 由于删除时没有没有更新表格和 stage 中序号内容，因此尽管某些情况下展示的序号和实际顺序并不对应
          // 但是表格中行和 stage 中图形对应关系不变，删除的动作也不会受到影响

          table.deleteRow(index + 1);
          objList.splice(index, 1);
          if (objList.length === 0){

            for (let radio of radios){
              radio.checked = false;
              radio.disabled = false;
            }

            for (let shapeRadio of shapeRadios){
              shapeRadio.checked = false;
              shapeRadio.disabled = true;
            }

            stage.removeAllEventListeners();

            table.hidden = true;
            buttonSubmit.hidden = false;

          }
        }
      }

      // 移除 stage 中空容器
      function clearStage() {
        for(let i = 1; i < stage.getNumChildren(); i++){
          if (stage.getChildAt(i).pointContainer){
            if (stage.getChildAt(i).pointContainer.getNumChildren() === 0){
              stage.removeChildAt(i);
              i--;
            }
          }
        }
      }

      // 根据障碍物在障碍物列表中的顺序添加序号
      function createNo(objList) {
        let index = objList.length - 1;
        let obj = objList[index];
        let x, y;
        // 障碍物为圆形
        // 圆形直径 > 3 则在圆心添加序号
        if (obj.points[0].r){
          if (obj.points[0].r > 1.5){
            x = obj.points[0].x;
            y = obj.points[0].y;
          }else {
            // 圆形直径 < 3 在圆形边缘添加序号
            // 默认边缘右侧，如果边缘右侧超出 stage 范围则添加到左侧
            x = obj.points[0].x + obj.points[0].r + 4 > bitmapW ? obj.points[0].x - obj.points[0].r -2 : obj.points[0].x + obj.points[0].r;
            y = obj.points[0].y;
          }
        }else{
          // 其他形状，分别找出所有点中 x 轴方向和 y 轴方向最远的点之间对应 x/y 坐标值
          // 形状足够大，则序号添加到中心，否则添加到边缘右侧，若边缘右侧空间不够则添加到左侧
          let arrayX = [], arrayY = [];
          for (let point of obj.points){
            arrayX.push(point.x);
            arrayY.push(point.y);
          }
          let x1 = Math.max(...arrayX), x2 = Math.min(...arrayX);
          let y1 = Math.max(...arrayY), y2 = Math.min(...arrayY);
          y = (y1 + y2)/2;
          if (x1 - x2 > 2 && y1 - y2 > 2){
            x = (x1 + x2)/2;
          }else{
            x = x1 + 2 > bitmapW ? x2 - 2 : x1
          }
        }
        let textBlock = new createjs.Text(index, "2px Arial");
        // 2px 大小 arial 字体
        textBlock.x = x;
        textBlock.y = -y;
        // obj.points 中坐标使用的坐标系中 y 轴正向朝上，stage 中坐标系 y 轴正向朝下
        textBlock.shadow = new createjs.Shadow("#000000", 3, 3, 3);
        // 添加阴影，有助于辨认
        console.log("text x y " + x + " , " + textBlock.y )
        stage.addChild(textBlock);
      }
    }

  </script>

</head>
<body onload = "init()">
<h1>Simple Map Example</h1>

<form>
  <p>请选择虚拟墙类型</p>
  <div>
    <input type="radio" id="type0" name="objType" value="carpets">
    <label for="type0">
      <canvas width="10" height="10" style="background-color: rgb(176, 219, 67 )">Carpets</canvas>
      carpets
    </label>

    <input type="radio" id="type1" name="objType" value="decelerations">
    <label for="type1">
      <canvas width="10" height="10" style="background-color: rgb(18,  234, 234)">Decelerations</canvas>
      decelerations
    </label>

    <input type="radio" id="type2" name="objType" value="displays">
    <label for="type2">
      <canvas width="10" height="10" style="background-color: rgb(188, 231, 253)">Displays</canvas>
      displays
    </label>

    <input type="radio" id="type3" name="objType" value="highlight">
    <label for="type3">
      <canvas width="10" height="10" style="background-color: rgb(196, 146, 177)">Highlight</canvas>
      highlight
    </label>

    <input type="radio" id="type4" name="objType" value="obstacles">
    <label for="type4">
      <canvas width="10" height="10" style="background-color: rgb(219, 39,  99 )">Obstacles</canvas>
      obstacles
    </label>

    <input type="radio" id="type5" name="objType" value="slopes">
    <label for="type5">
      <canvas width="10" height="10" style="background-color: rgb(240, 247, 87 )">Slopes</canvas>
      slopes
    </label>
  </div>
</form>
<form>
  <p>请选择标记形状</p>
  <div>
    <input type="radio" id="circles" name="shapeType" value="circles" disabled>
    <label for="circles">圆</label>

    <input type="text" id="radiusBox" placeholder="半径" hidden>
    <button type="button" id="saveRadius" hidden>确定</button>

    <input type="radio" id="lines" name="shapeType" value="lines" disabled>
    <label for="lines">线</label>

    <input type="radio" id="polygons" name="shapeType" value="polygons" disabled>
    <label for="polygons">多边形</label>

    <input type="radio" id="polylines" name="shapeType" value="polylines" disabled>
    <label for="polylines">折线</label>

    <input type="radio" id="rectangles" name="shapeType" value="rectangles" disabled>
    <label for="rectangles">方形</label>

    <button id="newObj" type="button" hidden>
      绘制新图形
    </button>

    <button id="finishObj" type="button" hidden>
      完成当前绘制
    </button>
  </div>
</form>
<div>
<canvas id="map" width="800" height="800" style="border:1px solid #f11010;"></canvas>
<table id="ptable" hidden>
  <thead>
  <tr>
    <th>序号</th>
    <th>类型</th>
    <th>形状</th>
    <th>坐标</th>
  </tr>
  </thead>
  <tbody>
  </tbody>
</table>
<button id="submitPoints" type="button">
  提交
</button>
</div>

</body>
</html>
