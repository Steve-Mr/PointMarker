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
        // comment

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

                // stage 自动刷新
                createjs.Ticker.framerate = 30;
                createjs.Ticker.addEventListener("tick", stage);

                stage.update();

                // polygon 初始化成功在 stage 上添加 polygon
                // 此时 polygon 在 bitmap 上层
                // 并设置 polygon 的点/线段的大小/粗细
                if (polygon!==null) {
                    polygon.pointSize = bitmapW * 0.01;
                    polygon.lineSize = bitmapW * 0.01 * 0.5;

                    // Add the polygon to the viewer
                    stage.addChild(new createjs.Shape());
                    stage.addChild(polygon);
                    stage.update();
                }

                loadMapObj();
            }

            // Event listeners for mouse interaction with the stage
            stage.mouseMoveOutside = false; // doesn't seem to work

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
                                polygon.addPoint(pos);
                                console.log(pos)
                                let coord = getDisplayCoord(pos);
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
            function getDisplayCoord(pos){
                this.pos = pos;
                return new coord({
                    type: document.querySelector('input[name="ptype"]:checked').value,
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

                // let paths = [];
                // paths.push(path1);
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

                // 表格中已经存在两行，所以标记点在表格中的对应位置需要 +2
                let tableIndex;
                let tr, cell0, cell1, cell2, cell3, cell4,    cell5;

                // 当一个点发生变动时需要更新附近点
                if (index === 0) {
                    if (coords.length > 1){
                        updateTable(coords, index);
                        updateTable(coords, (coords.length - 1));
                    }else{
                        updateTable(coords, index);
                    }
                } else {
                    updateTable(coords, index);
                    updateTable(coords, index - 1);
                }

                function updateTable(coords, index) {
                    console.log("updatetable " + index.toString())
                    calYaw(coords);
                    for (let i = 0; i < coords.length; i++) {
                        console.log(coords[i].toString());
                    }
                    tableIndex = index + 2;

                    // 标记点位置在最后 —— 需要添加显示该点的行
                    // 否则显示该点的行
                    // cell0: 类型
                    // cell1: 坐标
                    // cell2: 偏向角
                    // cell3: 名字——允许手动编辑
                    if (tableIndex === pTable.rows.length){
                        tr = pTable.insertRow(tableIndex);
                        cell0 = tr.insertCell(0);
                        cell1 = tr.insertCell(1);
                        cell2 = tr.insertCell(2);
                        cell3 = tr.insertCell(3);
                        cell4 = tr.insertCell(4);
                        cell5 = tr.insertCell(5);
                    }else{
                        tr = pTable.rows[tableIndex];
                        cell0 = tr.cells[0];
                        cell1 = tr.cells[1];
                        cell2 = tr.cells[2];
                        cell3 = tr.cells[3];
                        cell4 = tr.cells[4];
                    }

                    switch (coords[index].type) {
                        case "0":
                            cell0.innerHTML = "初始点";
                            break;
                        case "1":
                            cell0.innerHTML = "充电点";
                            break;
                        case "2":
                            cell0.innerHTML = "导航点";
                            break;
                        case "3":
                            cell0.innerHTML = "RFID点";
                            break;
                        case "4":
                            cell0.innerHTML = "注水点";
                            break;
                        case "5":
                            cell0.innerHTML = "排水点";
                            break;
                        default:
                            cell0.innerHTML = "未知/错误";
                            break;
                    }

                    cell1.innerHTML = coords[index].x.toString() + ", " + coords[index].y.toString();

                    cell2.innerHTML = coords[index].yaw.toString();

                    let element;
                    if (cell3.childNodes.length !== 0) {
                        element = cell3.childNodes[0];
                    }else{
                        element = document.createElement("input");
                        element.type = "text";
                        element.name = "pnameTextbox";
                        element.addEventListener('input', updateValue);
                    }

                    cell3.appendChild(element);
                    element.value = coords[index].name;
                    console.log("===");

                    let button;
                    if (cell4.childNodes.length !== 0){
                        button = cell4.childNodes[0];
                    }else{
                        button = document.createElement("button");
                        button.innerText = "delete";
                        cell4.appendChild(button);
                        button.addEventListener("click", deleteRow);
                    }

                    function updateValue() {
                        // 修改输入框内容时删除键变为保存键
                        // 只有输入框中值不为空才可以保存

                        button.innerText = "save";
                        button.disabled = element.value.length === 0;
                        button.removeEventListener("click", deleteRow);
                        button.addEventListener("click", makeChange);

                        function makeChange() {
                            if (element.value.length === 0) {
                                alert("please input point name");
                                return;
                            }
                            coords[index].name = element.value;
                            button.innerText = "delete";
                            button.removeEventListener("click", makeChange);
                            button.addEventListener("click", deleteRow);
                        }
                    }

                    function deleteRow() {
                        let index = button.parentNode.parentNode.rowIndex - 2;
                        deleteRowFun(index);
                    }
                }

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
                let httpRequest;
                document.getElementById("submitPoints").addEventListener('click', makeRequestAlt);

                function makeRequest() {

                    httpRequest = new XMLHttpRequest();

                    if (!httpRequest) {
                        alert('Giving up :( Cannot create an XML HTTP instance');
                        return false;
                    }
                    httpRequest.onreadystatechange = alertContents;
                    httpRequest.open('POST', 'https://0.0.0.0/test.html/gs-robot/cmd/generate_graph_path');
                    httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
                    httpRequest.send(generateResultJSON());

                    console.log(httpRequest);
                }

                function makeRequestAlt() {
                    // 在服务器上线后需要大量修改

                    httpRequest = new XMLHttpRequest();
                    if (!httpRequest) {
                        alert('Giving up :( Cannot create an XML HTTP instance');
                        return false;
                    }
                    httpRequest.open('POST', 'https://127.0.0.1/test.html/gs-robot/cmd/generate_graph_path');
                    httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
                    for (let i = 0; i < coords.length; i++){

                        coords[i].mapName = "${requestScope.name}";
                        // httpRequest.send(coords[i].toJSONAlt());
                        if (i === coords.length - 1){
                            httpRequest.onreadystatechange = alertContents;
                            httpRequest.send(coords[i].toJSONAlt());
                        }else{
                            // httpRequest.onreadystatechange = alertContentsAlt;

                        }

                        console.log(coords[i].toJSONAlt());
                        console.log(httpRequest);
                    }

                    <%--for (let i = 0; i < coords.length; i++){--%>
                    <%--    if (i === coords.length - 1){--%>
                    <%--        httpRequest.onreadystatechange = alertContents;--%>
                    <%--    }else{--%>
                    <%--        httpRequest.onreadystatechange = alertContentsAlt;--%>
                    <%--    }--%>
                    <%--    coords[i].mapName = "${requestScope.name}";--%>
                    <%--    httpRequest.send(coords[i].toJSONAlt());--%>
                    <%--}--%>
                }

                function alertContents() {
                    if (httpRequest.readyState === XMLHttpRequest.DONE) {
                        if (httpRequest.status === 200) {
                            alert(httpRequest.responseText);
                        } else {
                            alert('sent');
                        }
                    }
                }

                function alertContentsAlt() {
                    if (httpRequest.readyState === XMLHttpRequest.DONE) {
                        if (httpRequest.status === 200) {
                            alert("error occurred");
                            // 这里应该放到 else 框体中，为测试用进行对调
                        } else {
                        }
                    }
                }
            })();

            // 选择标记点的类型，只有在选择后才能进行点的标记
            let radios = document.querySelectorAll('input[name="ptype"]');
            for (const radio of radios) {
                    radio.addEventListener("change", function () {
                        stage.removeAllEventListeners();
                        registerMouseHandlers();
                    })
            }

            // 加载各种地图上的特殊对象
            function loadMapObj() {
                let mapObjs = ${requestScope.json};
                console.log(JSON.stringify(mapObjs));

                // let obstacles_polylines;
                let obj;
                let color;
                for (let key in mapObjs){
                    obj = mapObjs[key];
                    switch (key) {
                        case "carpets":
                            color = createjs.Graphics.getRGB(176, 219, 67, 1);
                            break;
                        case "decelerations":
                            color = createjs.Graphics.getRGB(18, 234, 234, 1);
                            break;
                        case "displays":
                            color = createjs.Graphics.getRGB(188, 231, 253, 1);
                            break;
                        case "highlight":
                            color = createjs.Graphics.getRGB(196, 146, 177, 1);
                            break;
                        case "obstacles":
                            color = createjs.Graphics.getRGB(219, 39, 99, 1);
                            break;
                        case "slopes":
                            color = createjs.Graphics.getRGB(240, 247, 87, 1);
                            break;
                        default :
                            continue;
                            break;
                    }
                    for (let key in obj){
                        drawObj(key, obj[key], color);
                    }
                }
            }

            // 根据坐标等参数在地图上绘制特殊对象
            function drawObj(objShape, obj, color) {
                function createPolygon(){
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

                switch (objShape.toString()) {
                    case "circles":
                        for (let i = 0; i < obj.length; i++){
                            // 使用 polygon 方法能够更容易将来实现拖动等操作
                            let polygon = createPolygon();
                            polygon.pointSize = obj[i].r;
                            let convertedPoint = getOnStageCoord(obj[i]);
                            let pos = {
                                x: convertedPoint.x,
                                y: convertedPoint.y,
                                z: 0};
                            polygon.addPoint(pos);
                            polygon.lineContainer.removeAllChildren();
                            stage.addChild(polygon);
                        }
                        break;
                    case "lines":
                        for (let i = 0; i < obj.length; i++){
                            let polygon = createPolygon();
                            for (let j = 0; j < obj[i].length; j++){
                                let convertedPoint = getOnStageCoord(obj[i][j]);
                                let pos = {
                                    x: convertedPoint.x,
                                    y: convertedPoint.y,
                                    z: 0};
                                polygon.addPoint(pos);
                            }
                            stage.addChild(polygon);
                        }
                        break;
                    case "polygons":
                        for (let i = 0; i < obj.length; i++){
                            for (let j = 0; j < obj[i].length; j++){
                                let convertedPoint = getOnStageCoord(obj[i][j]);
                                let pos = {
                                    x: convertedPoint.x,
                                    y: convertedPoint.y,
                                    z: 0};
                                polygon.addPoint(pos);
                            }
                            stage.addChild(polygon);
                        }
                        break;
                    case "polylines":
                        for (let i = 0; i < obj.length; i++){
                            let polygon = createPolygon();
                            polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);
                            for (let j = 0; j < obj[i].length; j++){
                                let convertedPoint = getOnStageCoord(obj[i][j]);
                                let pos = {
                                    x: convertedPoint.x,
                                    y: convertedPoint.y,
                                    z: 0};
                                polygon.addPoint(pos);
                            }
                            if (obj[i].length >= 3){
                                polygon.lineContainer.removeChildAt(obj[i].length - 1);
                            }
                            stage.addChild(polygon);
                        }
                        break;
                    case "rectangles":
                        for (let i = 0; i < obj.length; i++){
                            let polygon = createPolygon();
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
                            stage.addChild(polygon);
                        }
                        break;
                    default:
                        break;

                }
                stage.update();
            }
        }

    </script>

</head>
<body onload = "init()">
<h1>Simple Map Example</h1>

<form>
    <p>请选择标记点类型</p>
    <div>
        <input type="radio" id="type0" name="ptype" value="0">
        <label for="type0">初始点</label>

        <input type="radio" id="type1" name="ptype" value="1">
        <label for="type1">充电点</label>

        <input type="radio" id="type2" name="ptype" value="2">
        <label for="type2">导航点</label>

        <input type="radio" id="type3" name="ptype" value="3">
        <label for="type3">RFID 点</label>

        <input type="radio" id="type4" name="ptype" value="4">
        <label for="type4">注水点</label>

        <input type="radio" id="type5" name="ptype" value="5">
        <label for="type5">排水点</label>
    </div>
</form>
<canvas id="map" width="800" height="800" style="border:1px solid #f11010;"></canvas>
<div>
    <canvas width="10" height="10" style="background-color: rgb(176, 219, 67 )">Carpets</canvas>
    Carpets
    <canvas width="10" height="10" style="background-color: rgb(18,  234, 234)">Decelerations</canvas>
    Decelerations
    <canvas width="10" height="10" style="background-color: rgb(188, 231, 253)">Displays</canvas>
    Displays
    <canvas width="10" height="10" style="background-color: rgb(196, 146, 177)">Highlight</canvas>
    Highlight
    <canvas width="10" height="10" style="background-color: rgb(219, 39,  99 )">Obstacles</canvas>
    Obstacles
    <canvas width="10" height="10" style="background-color: rgb(240, 247, 87 )">Slopes</canvas>
    Slopes
</div>
<p id="points"></p>
<table id="ptable" hidden>
    <thead>
        <tr>
            <th colspan="4">已标记点</th>
        </tr>
        <tr>
            <th>类型</th>
            <th>坐标</th>
            <th>偏向角</th>
            <th>名字</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>
<button id="submitPoints" type="button" hidden>
    提交
</button>

</body>
</html>
