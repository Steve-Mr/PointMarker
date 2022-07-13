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

    /**
     * 坐标类
     * @param:type
     * 0 - 初始点
     * 1 - 充电点
     * 2 - 导航点
     * 3 - RFID 点
     * 4 - 注水点
     * 5 - 排水点
     * @param: x, y, yaw : 点的 x,y 坐标和偏向角
     * @param:name 点的名字默认为 Point_ + 年月（0-11）日(1-31) + 毫秒 + 五位随机数 格式
     *
     * @function:toString 输出字符串格式
     * @function:toJSON 输出 JSON 对象
     * */
    class coord {
      constructor(options) {
        options = options || {}

        let date = new Date();

        this.type = options.type || 6;
        this.x = options.x;
        this.y = options.y;
        this.yaw = options.yaw || 0.0;
        this.name = options.name ||
                "Point_"+date.getFullYear().toString()
                +date.getMonth().toString() +date.getDate().toString()
                +date.getMilliseconds().toString()+ "_"
                + (Math.random()).toString().slice(2, 7);
        this.mapName = options.mapName || "unset";
      }

      toString(){
        return this.type.toString() + " | "
                + this.x.toString() + ", "
                + this.y.toString() + ", "
                + this.yaw.toString() + ", "
                + this.name;
      }

      toJSON(){
        return {
          actions: [],
          gridPosition: {
            x: this.x,
            y: this.y
          },
          name: this.name
        };
      }

      toJSONAlt(){
        return {
          angle: this.yaw,
          gridX: this.x,
          gridY: this.y,
          mapName: this.mapName,
          name: this.name,
          type: this.type
        }
      }
    }

    /**
     * 线段类
     *
     * @param:sPoint 起始点
     * @param:ePoint 终止点
     * @param:name 线段名，默认使用 起始点名称_终止点名称
     *
     * @function:toJSON 输出对应 JSON 对象
     * */
    class line{
      constructor(options) {
        this.sPoint = options.sPoint;
        this.ePoint = options.ePoint;
        this.name = options.name || this.sPoint.name + "_" + this.ePoint.name;
      }

      toJSON(){
        return {
          begin: this.sPoint.name,
          end: this.ePoint.name,
          name: this.name,
          radius: 0
        };
      }
    }

    /**
     * 路径类
     *
     * @Param:allPoints 所有已标记点，即使路径可能不经过该点
     * @Param:allLines 路径包含所有线段的名字集合
     * @Param:name 路径名，Path_ + 毫秒 + 五位随机数
     *
     * @function:toJSON 输出对应 JSON 对象
     * */
    class path{
      constructor(options) {
        this.allPoints = options.allPoints;
        this.allLines  = options.allLines;
        this.name = options.name || 'Path_' + new Date().getMilliseconds().toString()+ "_"
                + (Math.random()).toString().slice(2, 7);
      }

      toJSON(){
        let result = {
          lines:[],
          name: this.name,
          points:[]
        }

        for (let i = 0; i < this.allPoints.length; i++){
          result.points.push(this.allPoints[i].toJSON());
        }

        for (let i = 0; i < this.allLines.length; i++){
          result.lines.push(
                  {
                    name: this.allLines[i].name
                  }
          )
        }

        return result;
      }
    }

    /**
     * 路径组
     * 包含多条路径
     *
     * @param:paths 路径组包含的所有路径集合
     *
     * @function:toJSON 输出 JSON 对象
     * */
    class pathGroup{
      constructor(options) {
        this.paths = options.paths;
      }

      toJSON(){
        let result = {
          name: 'pathgroup_'+ new Date().getMilliseconds().toString()+ "_"
                  + (Math.random()).toString().slice(2, 7),
          paths: [],
          type: "normal"
        }

        for (let i = 0; i < this.paths.length; i++){
          result.paths.push(
                  {
                    name: this.paths[i].name
                  }
          );
        }

        return result;
      }
    }

    function init() {
      console.log("init...");

      /**
       * request 中参数：
       * status: 数据获取是否成功，失败则返回前一页
       * url: 地图的图片链接
       * resolution, originX, originY: 同地图定义
       * */

      let originX = 0;
      let originY = 0;

      if (!${requestScope.status}){
        alert("error occurred");
        history.back();
        return;
      }

      originX = ${requestScope.originX};
      originY = ${requestScope.originY};

      let canvas = document.getElementById("map");    // 展示地图
      let stage = new createjs.Stage(canvas);
      let pTable = document.getElementById("ptable"); // 已标记点表格

      let bitmap = new createjs.Bitmap(${requestScope.url});
      bitmap.scaleX = ${requestScope.resolution};
      bitmap.scaleY = ${requestScope.resolution};

      // 标记点和线段数组
      let coords = [];
      let lines = [];
      let points = [];

      let preType, preShape;
      let polygonIndex = 0;

      // 缩放视图
      let zoomView = new ROS2D.ZoomView({
        rootObject: stage
      });
      // 平移视图
      let panView = new ROS2D.PanView({
        rootObject: stage
      });

      // 鼠标点击 polygon 时的回调函数
      let clickedPolygon = false;
      let selectedPointIndex = null;

      // 记录没有设置半径时第一次点击坐标
      let isRadiusUnsetClicked = false;
      let coordCircle;

      let objList = [];
      let linesPos = [];
      let rectPos = [];
      let polyPos = [];

      let pointCallBack = function (type, event, index) {
        if (type === 'mousedown') {
          // 按住 shift 点击点则移除此点，未按住 shift 只选中此点
          if (event.nativeEvent.shiftKey === true) {
            deleteRowFun(index)
          }
          else {
            selectedPointIndex = index;
          }
        }
        clickedPolygon = true;
      };

      let lineCallBack = function (type, event, index) {
      }

      // 创建 polygon，用于显示标记点和将标记点连接——即线段
      let polygon = new ROS2D.PolygonMarker({
        pointColor: createjs.Graphics.getRGB(255, 0, 0, 0.66),
        lineColor: createjs.Graphics.getRGB(100, 100, 255, 1),
        pointCallBack: pointCallBack,
        lineCallBack: lineCallBack,
      });

      // Hack. 用于避免 polygon 在线段围成区域上添加遮罩——设置该遮罩透明度 100%
      // in source code : this.fillColor = options.pointColor || createjs.Graphics.getRGB(0, 255, 0, 0.33);
      polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);

      // 地图代表物理区域大小，单位为米，即地图图片大小 * 比例
      let bitmapW;
      let bitmapH;
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
        polygonIndex ++;
        console.log("polygon index 1");

        // stage 自动刷新
        createjs.Ticker.framerate = 30;
        createjs.Ticker.addEventListener("tick", stage);

        stage.update();

        // polygon 初始化成功在 stage 上添加 polygon
        // 此时 polygon 在 bitmap 上层
        // 并设置 polygon 的点/线段的大小/粗细
        if (polygon!==null) {
          polygon.pointSize = bitmapW * 0.01 * 0.5;
          polygon.lineSize = bitmapW * 0.01 * 0.5;

          // Add the polygon to the viewer
          stage.addChild(polygon);
          polygonIndex ++;
          console.log("polygon index 2");

          stage.update();
        }
        // Event listeners for mouse interaction with the stage
        stage.mouseMoveOutside = false; // doesn't seem to work

        loadMapObj();
      }

      // 选择标记点的类型，只有在选择后才能进行点的标记
      let radios = document.querySelectorAll('input[name="objType"]');
      for (const radio of radios) {
        radio.addEventListener("change", function () {
          // console.log(radio.value);
          let color = getObjColor(radio.value);
          polygon.pointColor = color;
          polygon.lineColor = color;
          polygon.fillColor = color;
          let shapeRadios = document.querySelectorAll('input[name="shapeType"]');
          stage.removeAllEventListeners();
          for (let shapeRadio of shapeRadios){
            shapeRadio.checked = false;
            shapeRadio.disabled = false;
            shapeRadio.addEventListener("change", function () {
              archiveExistedPoly();
              preType = radio.value;
              console.log("pretype  ", preType.toString());

              stage.removeAllEventListeners();
              registerMouseHandlers();

              addNewPolygon();
              document.getElementById("newObj").disabled = true;

              switch (shapeRadio.value) {
                case "circles":
                  break;
                case "lines":
                  break;
                case "polygon":
                  break;
                case "polylines":
                  polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);
                  break;
                case "rectangles":
                  break;

              }
              preShape = shapeRadio.value;
              // shapeRadio.disabled = true;

            })
          }
        })
      }

      function archiveExistedPoly() {
        if (polyPos.length !== 0){
          addToObjList({
            type: preType? preType : document.querySelector('input[name="objType"]:checked').value,
            shape: preShape? preShape : document.querySelector('input[name="shapeType"]:checked').value,
            points: polyPos
          });
          polyPos = [];
        }
      }

      function registerMouseHandlers() {
        // 处理鼠标操作
        // 单击添加点
        // 按住 ctrl 点击不放拖动鼠标： 缩放地图
        // 按住 shift 点击不放拖动鼠标： 移动地图（可能会和移除点冲突）
        // 未按键时可以拖动点
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
            else {
              if (selectedPointIndex !== null) {
                let pos = stage.globalToRos(event.stageX, event.stageY);
                polygon.movePoint(selectedPointIndex, pos);
                coords[selectedPointIndex].x = Math.round(pos.x - originX);
                coords[selectedPointIndex].y = Math.round(pos.y+bitmapH-originY);
                printCoords(coords, selectedPointIndex);
              }
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
                let key = document.querySelector('input[name="shapeType"]:checked').value;

                switch (key){
                  case "circles":
                    let radiusBox = document.getElementById("radiusBox");
                    radiusBox.addEventListener('input', updatePoint);
                    let buttonSave = document.getElementById("saveRadius");
                    buttonSave.addEventListener("click", createCircle);
                    let prePointSize = polygon.pointSize;

                    if(!isRadiusUnsetClicked){
                      coordCircle = pos;
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
                      pos = coordCircle;
                    }
                    polygon.addPoint(pos);
                    polygon.pointSize = prePointSize;

                    addToObjList({
                      type: document.querySelector('input[name="objType"]:checked').value,
                      shape: document.querySelector('input[name="shapeType"]:checked').value,
                      points: [pos],
                      radius: radiusBox.value
                    })
                    isRadiusUnsetClicked = false;

                    buttonSave.removeEventListener("click",createCircle);
                    radiusBox.removeEventListener("input", updatePoint);
                  }

                    break;
                  case "lines":
                    if (polygon.pointContainer.getNumChildren() !== 2){
                      linesPos.push(pos);
                      console.log("linepos pushed" + pos.x);
                      polygon.addPoint(pos);

                      if (polygon.pointContainer.getNumChildren() === 2){
                        addToObjList({
                          type: document.querySelector('input[name="objType"]:checked').value,
                          shape: document.querySelector('input[name="shapeType"]:checked').value,
                          points: linesPos,
                        })
                        linesPos = [];
                      }
                    } else {
                      addNewPolygon();
                      linesPos.push(pos);
                      console.log("linepos pushed" + pos.x);
                      polygon.addPoint(pos);

                    }
                    break;
                  case "polygons":
                    document.getElementById("newObj").hidden = false;
                    // console.log("polygon points " + polygon.pointContainer.getNumChildren());
                    polygon.addPoint(pos);
                    polyPos.push(pos);
                    document.getElementById("newObj").disabled = false;
                    document.getElementById("newObj").addEventListener('click', updateObj)
                    break;
                  case "polylines":
                    document.getElementById("newObj").hidden = false;
                    points.push(pos);
                    polyPos.push(pos);
                    document.getElementById("newObj").disabled = false;
                    document.getElementById("newObj").addEventListener('click', updateObj)

                    polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);
                    if (polygon.pointContainer.getNumChildren() >= 2){
                      polygon.pointContainer.removeAllChildren();
                      polygon.lineContainer.removeAllChildren();
                      polygon.drawFill();
                      for (let i = 0; i < points.length; i++){
                        polygon.addPoint(points[i]);
                      }
                      polygon.lineContainer.removeChildAt(polygon.lineContainer.getNumChildren() -1);
                    }else{
                      polygon.addPoint(pos);
                    }
                    break;
                  case "rectangles":
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

                      rectPos = [];

                      addNewPolygon();
                    }
                    break;
                  default:
                    break;

                }

                // console.log(pos)
                let coord = geDisplayCoord(pos);
                coords.push(coord);

                printCoords(coords, coords.length-1);
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
      function geDisplayCoord(pos){
        this.pos = pos;
        return new coord({
          type: document.querySelector('input[name="objType"]:checked').value,
          x : Math.round(this.pos.x - originX),
          y : Math.round(this.pos.y+bitmapH-originY)});
      }

      function getOnStageCoord(obj){
        return {
          x: obj.x + originX,
          y: obj.y + originY - bitmapH
        };
      }

      // 根据线段方向计算偏向角，使用弧度单位，逆时针方向为正，x 轴正向为 0
      // 只有一个点时偏向角为 0
      function calYaw(coords){
        for (let index = 0; index <coords.length; index++){
          let coord1 = coords[index];
          let coord2;
          if(index !== coords.length-1){
            coord2 = coords[index+1];
          }else{
            coord2 = coords[0];
          }
          coords[index].yaw = Math.atan2(coord2.y - coord1.y, coord2.x - coord1.x).toFixed(2);
        }
      }

      // 依据已标记点的顺序生成所有线段
      function retrieveLines() {
        let i;
        for (i = 0; i < coords.length-1; i++){
          lines.push(new line({sPoint:coords[i], ePoint:coords[i+1]}));
        }
        lines.push(new line({sPoint:coords[i], ePoint:coords[0]}));
      }

      // 生成返回服务器的 JSON 字符串，格式参照 1.7.1 生成手画路径部分。
      function generateResultJSON() {

        let result =
                {
                  points: [],
                  lines: [],
                  mapName: "${requestScope.name}",
                  name: new Date().getMilliseconds().toString() + (Math.random()).toString().slice(2, 7),
                  pathGroups: [],
                  paths: []
                };

        for (let i = 0; i < coords.length; i++){
          result.points.push(coords[i].toJSON());
        }

        retrieveLines();

        for (let i = 0; i < lines.length; i++){
          result.lines.push(lines[i].toJSON());
        }

        let path1 = new path({allPoints: coords, allLines: lines});
        result.paths.push(path1.toJSON());

        result.pathGroups.push(new pathGroup({paths: [path1]}).toJSON());

        console.log(JSON.stringify(result));

        return JSON.stringify(result);
      }

      /**
       * 在表格中添加或修改某一个标记点信息
       *
       * @param:coords 包含标记点的数组
       * @param:index 标记点在数组中位置
       * */
      function printCoords(coords, index){
        pTable.hidden = false;

        // // 表格中已经存在两行，所以标记点在表格中的对应位置需要 +2
        // let tableIndex;
        // let tr, cell0, cell1, cell2, cell3, cell4;
        //
        // // 当一个点发生变动时需要更新附近点
        // if (index === 0) {
        //   if (coords.length > 1){
        //     updateTable(coords, index);
        //     updateTable(coords, (coords.length - 1));
        //   }else{
        //     updateTable(coords, index);
        //   }
        // } else {
        //   updateTable(coords, index);
        //   updateTable(coords, index - 1);
        // }
        //
        // function updateTable(coords, index) {
        //   // console.log("update table " + index.toString())
        //   calYaw(coords);
        //   for (let i = 0; i < coords.length; i++) {
        //     // console.log(coords[i].toString());
        //   }
        //   tableIndex = index + 2;
        //
        //   // 标记点位置在最后 —— 需要添加显示该点的行
        //   // 否则显示该点的行
        //   // cell0: 类型
        //   // cell1: 坐标
        //   // cell2: 偏向角
        //   // cell3: 名字——允许手动编辑
        //   if (tableIndex === pTable.rows.length){
        //     tr = pTable.insertRow(tableIndex);
        //     cell0 = tr.insertCell(0);
        //     cell1 = tr.insertCell(1);
        //     cell2 = tr.insertCell(2);
        //     cell3 = tr.insertCell(3);
        //     cell4 = tr.insertCell(4);
        //   }else{
        //     tr = pTable.rows[tableIndex];
        //     cell0 = tr.cells[0];
        //     cell1 = tr.cells[1];
        //     cell2 = tr.cells[2];
        //     cell3 = tr.cells[3];
        //     cell4 = tr.cells[4];
        //   }
        //
        //   switch (coords[index].type) {
        //     case "0":
        //       cell0.innerHTML = "初始点";
        //       break;
        //     case "1":
        //       cell0.innerHTML = "充电点";
        //       break;
        //     case "2":
        //       cell0.innerHTML = "导航点";
        //       break;
        //     case "3":
        //       cell0.innerHTML = "RFID点";
        //       break;
        //     case "4":
        //       cell0.innerHTML = "注水点";
        //       break;
        //     case "5":
        //       cell0.innerHTML = "排水点";
        //       break;
        //     default:
        //       cell0.innerHTML = "未知/错误";
        //       break;
        //   }
        //
        //   cell1.innerHTML = coords[index].x.toString() + ", " + coords[index].y.toString();
        //
        //   cell2.innerHTML = coords[index].yaw.toString();
        //
        //   let element;
        //   if (cell3.childNodes.length !== 0) {
        //     element = cell3.childNodes[0];
        //   }else{
        //     element = document.createElement("input");
        //     element.type = "text";
        //     element.name = "pnameTextbox";
        //     element.addEventListener('input', updateValue);
        //   }
        //
        //   cell3.appendChild(element);
        //   element.value = coords[index].name;
        //   // console.log("===");
        //
        //   let button;
        //   if (cell4.childNodes.length !== 0){
        //     button = cell4.childNodes[0];
        //   }else{
        //     button = document.createElement("button");
        //     button.innerText = "delete";
        //     cell4.appendChild(button);
        //     button.addEventListener("click", deleteRow);
        //   }
        //
        //   function updateValue() {
        //     // 修改输入框内容时删除键变为保存键
        //     // 只有输入框中值不为空才可以保存
        //
        //     button.innerText = "save";
        //     button.disabled = element.value.length === 0;
        //     button.removeEventListener("click", deleteRow);
        //     button.addEventListener("click", makeChange);
        //
        //     function makeChange() {
        //       if (element.value.length === 0) {
        //         alert("please input point name");
        //         return;
        //       }
        //       coords[index].name = element.value;
        //       button.innerText = "delete";
        //       button.removeEventListener("click", makeChange);
        //       button.addEventListener("click", deleteRow);
        //     }
        //   }
        //
        //   function deleteRow() {
        //     let index = button.parentNode.parentNode.rowIndex - 2;
        //     deleteRowFun(index);
        //   }
        // }

        document.getElementById("submitPoints").hidden = false;
      }

      function deleteRowFun(index){
        this.index = index;
        polygon.remPoint(this.index);
        coords.splice(this.index, 1);
        pTable.deleteRow(this.index+2);
        if (pTable.rows.length === 2){
          document.getElementById("submitPoints").hidden = true;
          pTable.hidden = true;
        }
      }

      // 点击提交按钮像服务器提交已标记点/线段/路径/路径组信息
      (function() {
        document.getElementById("submitPoints").addEventListener('click', printObjInfo);
        function printObjInfo() {
          archiveExistedPoly();

          console.log("stage children num " + stage.getNumChildren().toString());

        }
        <%--let httpRequest;--%>
        <%--document.getElementById("submitPoints").addEventListener('click', makeRequestAlt);--%>

        <%--function makeRequest() {--%>

        <%--  httpRequest = new XMLHttpRequest();--%>

        <%--  if (!httpRequest) {--%>
        <%--    alert('Giving up :( Cannot create an XML HTTP instance');--%>
        <%--    return false;--%>
        <%--  }--%>
        <%--  httpRequest.onreadystatechange = alertContents;--%>
        <%--  httpRequest.open('POST', 'https://0.0.0.0/test.html/gs-robot/cmd/generate_graph_path');--%>
        <%--  httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')--%>
        <%--  httpRequest.send(generateResultJSON());--%>

        <%--  console.log(httpRequest);--%>
        <%--}--%>

        <%--function makeRequestAlt() {--%>
        <%--  // 在服务器上线后需要大量修改--%>

        <%--  httpRequest = new XMLHttpRequest();--%>
        <%--  if (!httpRequest) {--%>
        <%--    alert('Giving up :( Cannot create an XML HTTP instance');--%>
        <%--    return false;--%>
        <%--  }--%>
        <%--  httpRequest.open('POST', 'https://127.0.0.1/test.html/gs-robot/cmd/generate_graph_path');--%>
        <%--  httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')--%>
        <%--  for (let i = 0; i < coords.length; i++){--%>

        <%--    coords[i].mapName = "${requestScope.name}";--%>
        <%--    // httpRequest.send(coords[i].toJSONAlt());--%>
        <%--    if (i === coords.length - 1){--%>
        <%--      httpRequest.onreadystatechange = alertContents;--%>
        <%--      httpRequest.send(coords[i].toJSONAlt());--%>
        <%--    }else{--%>
        <%--      // httpRequest.onreadystatechange = alertContentsAlt;--%>

        <%--    }--%>

        <%--    // console.log(coords[i].toJSONAlt());--%>
        <%--    console.log(httpRequest);--%>
        <%--  }--%>

        <%--  &lt;%&ndash;for (let i = 0; i < coords.length; i++){&ndash;%&gt;--%>
        <%--  &lt;%&ndash;    if (i === coords.length - 1){&ndash;%&gt;--%>
        <%--  &lt;%&ndash;        httpRequest.onreadystatechange = alertContents;&ndash;%&gt;--%>
        <%--  &lt;%&ndash;    }else{&ndash;%&gt;--%>
        <%--  &lt;%&ndash;        httpRequest.onreadystatechange = alertContentsAlt;&ndash;%&gt;--%>
        <%--  &lt;%&ndash;    }&ndash;%&gt;--%>
        <%--  &lt;%&ndash;    coords[i].mapName = "${requestScope.name}";&ndash;%&gt;--%>
        <%--  &lt;%&ndash;    httpRequest.send(coords[i].toJSONAlt());&ndash;%&gt;--%>
        <%--  &lt;%&ndash;}&ndash;%&gt;--%>
        <%--}--%>

        <%--function alertContents() {--%>
        <%--  if (httpRequest.readyState === XMLHttpRequest.DONE) {--%>
        <%--    if (httpRequest.status === 200) {--%>
        <%--      alert(httpRequest.responseText);--%>
        <%--    } else {--%>
        <%--      alert('sent');--%>
        <%--    }--%>
        <%--  }--%>
        <%--}--%>

        <%--function alertContentsAlt() {--%>
        <%--  if (httpRequest.readyState === XMLHttpRequest.DONE) {--%>
        <%--    if (httpRequest.status === 200) {--%>
        <%--      alert("error occurred");--%>
        <%--      // 这里应该放到 else 框体中，为测试用进行对调--%>
        <%--    } else {--%>
        <%--    }--%>
        <%--  }--%>
        <%--}--%>
      })();

      function createPolygon(color){
        return new ROS2D.PolygonMarker({
          pointColor: color,
          lineColor: color,
          pointCallBack: pointCallBack,
          lineCallBack: lineCallBack,
          pointSize: bitmapW * 0.01 * 0.5,
          lineSize: bitmapW * 0.01 * 0.5,
          fillColor: color
        });
      }

      // 加载各种地图上的特殊对象
      function loadMapObj() {
        let mapObjs = ${requestScope.json};
        console.log(JSON.stringify(mapObjs));

        let obj;
        let color;
        for (let key in mapObjs){
          if (key.includes("World")) continue;
          obj = mapObjs[key];
          // color = getObjColor(key);
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
              // 使用 polygon 方法能够更容易将来实现拖动等操作
              let polygon = createPolygon(getObjColor(type));
              polygon.pointSize = obj[i].r;
              let convertedPoint = getOnStageCoord(obj[i]);
              let pos = {
                x: convertedPoint.x,
                y: convertedPoint.y,
                z: 0};
              polygon.addPoint(pos);
              polygon.lineContainer.removeAllChildren();
              stage.addChild(polygon);
              polygonIndex ++;
              console.log("polygon index 3");


              addToObjList({
                type: type,
                shape: objShape,
                points: [pos],
                radius: obj[i].r
              })
            }
            break;
          case "lines":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(getObjColor(type));
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
              polygonIndex ++;
              console.log("polygon index 4");

              addToObjList({
                type: type,
                shape: objShape,
                points: points
              })

            }
            break;
          case "polygons":
            for (let i = 0; i < obj.length; i++){
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
              polygonIndex ++;
              console.log("polygon index 5");


              addToObjList({
                type: type,
                shape: objShape,
                points: points
              })
            }
            break;
          case "polylines":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(getObjColor(type));
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
              console.log("pre draw " + type);

              stage.addChild(polygon);
              polygonIndex ++;
              console.log("polygon index 6");

            }
            break;
          case "rectangles":
            for (let i = 0; i < obj.length; i++){
              let polygon = createPolygon(getObjColor(type));
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
                points: [obj[i][0], obj[i][1]]
              })
              stage.addChild(polygon);
              polygonIndex ++;
              console.log("polygon index 7");

            }
            break;
          default:
            break;

        }
        stage.update();
      }

      function getObjColor(key) {
        switch (key) {
          case "carpets":
            return createjs.Graphics.getRGB(176, 219, 67, 1);
          case "decelerations":
            return createjs.Graphics.getRGB(18, 234, 234, 1);
          case "displays":
            return createjs.Graphics.getRGB(188, 231, 253, 1);
          case "highlight":
            return createjs.Graphics.getRGB(196, 146, 177, 1);
          case "obstacles":
            return createjs.Graphics.getRGB(219, 39, 99, 1);
          case "slopes":
            return createjs.Graphics.getRGB(240, 247, 87, 1);
          default :
            return null;
        }

      }
      function addNewPolygon() {
        polygon = createPolygon(
                getObjColor(
                        document.querySelector('input[name="objType"]:checked').value
                ));
        stage.addChild(polygon);
        polygonIndex ++;
        console.log("polygon index 8");

        stage.update();
        points = [];
      }

      function updateObj() {
        archiveExistedPoly();
        addNewPolygon();
        // addToObjList({
        //   type: document.querySelector('input[name="objType"]:checked').value,
        //   shape: document.querySelector('input[name="shapeType"]:checked').value,
        //   points: polyPos
        // });
        polyPos = [];
        document.getElementById("newObj").disabled = true;
        document.getElementById("newObj").removeEventListener("click", updateObj);
      }

      function addToObjList(options) {
        this.type = options.type;
        this.shape = options.shape;
        this.points = options.points;
        this.radius = options.radius || 0;
        this.stageIndex = polygonIndex;


        // 在屏幕上输出信息
        let table = document.getElementById("ptable");
        table.hidden = false;
        let tr = table.insertRow(table.rows.length);
        let cell0 = tr.insertCell(0);
        let cell1 = tr.insertCell(1);
        let cell2 = tr.insertCell(2);
        let cell3 = tr.insertCell(3);

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

        function deleteRow() {
          clearStage();
          console.log("stageindex " + stage.getNumChildren());

          let index = button.parentNode.parentNode.rowIndex -1;
          stage.removeChildAt(index + 1);
          table.deleteRow(index + 1);
          objList.splice(index, 1);
        }

        if (this.radius === 0){
          objList.push({
            type: this.type,
            shape: this.shape,
            points: this.points,
            stageIndex: this.stageIndex
          });
        }else {
          objList.push({
            type: this.type,
            shape: this.shape,
            points: this.points,
            radius: this.radius,
            stageIndex: this.stageIndex
          });
        }

        function getXY(points, radius) {
          let pointString = "";
          if (radius === 0){
            for (let point of points){
              pointString += " {x: "+ point.x + ", y: " + point.y + "}";
            }
          }else{
            for (let point of points){
              pointString += " {x: "+ point.x + ", y: " + point.y + ", r: " + radius +"}";
            }
          }

          return pointString;
        }
      }
      function clearStage() {
        for(let i = 1; i < stage.getNumChildren(); i++){
          if (stage.getChildAt(i).pointContainer.getNumChildren() === 0){
            stage.removeChildAt(i);
            i--;
          }
        }
        
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
    <label for="circles">点</label>

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
  </div>
</form>
<button id="newObj" type="button" hidden>
  绘制新图形
</button>
<canvas id="map" width="800" height="800" style="border:1px solid #f11010;"></canvas>
<p id="points"></p>
<table id="ptable" hidden>
  <thead>
  <tr>
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

</body>
</html>
