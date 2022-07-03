<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Created by IntelliJ IDEA.
  User: maary
  Date: 2022/6/30
  Time: 上午11:30
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>

    <title>Map</title>

    <meta charset="utf-8"/>

    <script type="text/javascript" src="https://static.robotwebtools.org/EaselJS/current/easeljs.min.js"></script>
    <script type="text/javascript"
            src="https://static.robotwebtools.org/EventEmitter2/current/eventemitter2.min.js"></script>
    <script type="text/javascript" src="https://static.robotwebtools.org/roslibjs/current/roslib.min.js"></script>
    <script type="text/javascript" src="https://static.robotwebtools.org/ros2djs/current/ros2d.min.js"></script>

    <script type="text/javascript" type="text/javascript">
        // comment
        // return 坐标点

        class coord {
            constructor(options) {
                options = options || {}

                var date = new Date();

                this.type = options.type || 6;
                this.x = options.x;
                this.y = options.y;
                this.yaw = options.yaw || 0.0;
                this.name = options.name ||
                    "Point_"+date.getFullYear().toString()
                    +date.getMonth().toString() +date.getDate().toString()
                    +date.getMilliseconds().toString()+ "_"
                    + (Math.random()).toString().slice(2, 7);
            }

            toString(){
                return this.type.toString() + " | "
                    + this.x.toString() + ", "
                    + this.y.toString() + ", "
                    + this.yaw.toString() + ", "
                    + this.name;
            }

            toJSON(){
                // return JSON.stringify(
                return {
                    actions: [],
                    gridPosition: {
                        x: this.x,
                        y: this.y
                    },
                    name: this.name
                };
            }
        }

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

            // for (var i = 0; i < 100; i++){
            //     console.log((Math.random()).toString().slice(2, 7));
            // }

            var image_url = ${url};
            var canvas = document.getElementById("map");
            var stage = new createjs.Stage(canvas);
            var bitmap = new createjs.Bitmap(image_url);
            var resolution = ${resolution};
            var originX = ${originX};
            var originY = ${originY};

            var pTable = document.getElementById("ptable");

            var pointsBlock = document.getElementById("points");

            bitmap.scaleX = resolution;
            bitmap.scaleY = resolution;

            var coords = [];
            var lines = [];

            console.log(image_url.toString());
            stage.addChild(bitmap);
            createjs.Ticker.framerate = 30;
            createjs.Ticker.addEventListener("tick", stage);

            console.log("stage.scaleX before: " + stage.scaleX.toString() + ", stage.scaleY before: " + stage.scaleY.toString());

            let bitmapW;
            let bitmapH;
            bitmap.image.onload = function () {

                bitmapW = bitmap.image.width;
                bitmapH = bitmap.image.height;
                // restore to values before shifting, if occurred
                stage.x = typeof stage.x_prev_shift !== 'undefined' ? stage.x_prev_shift : stage.x;
                stage.y = typeof stage.y_prev_shift !== 'undefined' ? stage.y_prev_shift : stage.y;

                console.log(bitmap.getBounds().width.toString());

                // save scene scaling
                stage.scaleX = 800 / (bitmapW * resolution);
                stage.scaleY = 800 / (bitmapH * resolution);

                stage.update();

                if (polygon!==null){
                    polygon.pointSize = bitmapW * resolution * 0.01;
                    polygon.lineSize = bitmapW * resolution * 0.01 * 0.5;
                }
            }

            console.log("stage.scaleX now: " + stage.scaleX.toString() + ", stage.scaleY now: " + stage.scaleY.toString());

            // Add zoom to the viewer.
            var zoomView = new ROS2D.ZoomView({
                rootObject: stage
            });
            // Add panning to the viewer.
            var panView = new ROS2D.PanView({
                rootObject: stage
            });

            // Callback functions when there is mouse interaction with the polygon
            var clickedPolygon = false;
            var selectedPointIndex = null;

            var pointCallBack = function (type, event, index) {
                if (type === 'mousedown') {
                    if (event.nativeEvent.shiftKey === true) {
                        polygon.remPoint(index);
                        coords.splice(index, 1);
                        pTable.deleteRow(index+2);
                        // printCoords(pointsBlock, coords);
                    }
                    else {
                        selectedPointIndex = index;
                    }
                }
                clickedPolygon = true;
            };

            var lineCallBack = function (type, event, index) {
                // if (type === 'mousedown') {
                //     if (event.nativeEvent.ctrlKey === true) {
                //         polygon.splitLine(index);
                //         coords = []
                //         for(var i = 0; i < polygon.pointContainer.getNumChildren(); i ++){
                //             var pos = polygon.pointContainer.getChildAt(i);
                //             coords.push(getActualCoord(pos));
                //         }
                //         printCoords(pointsBlock, coords);
                //     }
                // }
                // clickedPolygon = true;
            }

            // Create the polygon
            var polygon = new ROS2D.PolygonMarker({
                pointColor: createjs.Graphics.getRGB(255, 0, 0, 0.66),
                lineColor: createjs.Graphics.getRGB(100, 100, 255, 1),
                pointCallBack: pointCallBack,
                lineCallBack: lineCallBack,
                pointSize: bitmapW * resolution * 0.01,
                lineSize: bitmapW * resolution * 0.01 * 0.5
            });

            console.log(polygon.pointColor);

            // Hack
            // in source code : this.fillColor = options.pointColor || createjs.Graphics.getRGB(0, 255, 0, 0.33);
            polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);

            // Add the polygon to the viewer
            stage.addChild(new createjs.Shape());
            stage.addChild(polygon);
            stage.update();

            // Event listeners for mouse interaction with the stage
            stage.mouseMoveOutside = false; // doesn't seem to work

            function registerMouseHandlers() {
                // Setup mouse event handlers
                var mouseDown = false;
                var zoomKey = false;
                var panKey = false;
                var startPos = new ROSLIB.Vector3();

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
                            var dy = event.stageY - startPos.y;
                            var zoom = 1 + 10 * Math.abs(dy) / stage.canvas.clientHeight;
                            if (dy < 0)
                                zoom = 1 / zoom;
                            zoomView.zoom(zoom);
                        }
                        else if (panKey === true) {
                            panView.pan(event.stageX, event.stageY);
                        }
                        else {
                            if (selectedPointIndex !== null) {
                                var pos = stage.globalToRos(event.stageX, event.stageY);
                                polygon.movePoint(selectedPointIndex, pos);
                                coords[selectedPointIndex].x = Math.round(pos.x - originX);
                                coords[selectedPointIndex].y = Math.round(pos.y+(bitmap.image.height * resolution)-originY);
                                printCoords(coords, selectedPointIndex);
                                // TODO: better output
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
                                var pos = stage.globalToRos(event.stageX, event.stageY);
                                polygon.addPoint(pos);
                                var coord = getActualCoord(pos);
                                coords.push(coord);

                                printCoords(coords, coords.length-1);
                            }
                            clickedPolygon = false;
                        }
                        mouseDown = false;
                    }
                });
            }

            function getActualCoord(pos){
                this.pos = pos;
                return new coord({
                    type: document.querySelector('input[name="ptype"]:checked').value,
                    x : Math.round(this.pos.x - originX),
                    y : Math.round(this.pos.y+(bitmap.image.height * resolution)-originY)});
            }

            function calYaw(coords){
                for (var index = 0; index <coords.length; index++){
                    var coord1 = coords[index];
                    if(index !== coords.length-1){
                        var coord2 = coords[index+1];
                    }else{
                        var coord2 = coords[0];
                    }
                    coords[index].yaw = Math.atan2(coord2.y - coord1.y, coord2.x - coord1.x).toFixed(2);
                }
            }

            function retrieveLines() {
                var i;
                for (i = 0; i < coords.length-1; i++){
                    lines.push(new line({sPoint:coords[i], ePoint:coords[i+1]}));
                }
                lines.push(new line({sPoint:coords[i], ePoint:coords[0]}));
            }

            function generateResultJSON() {
                let result =
                    {
                        points: [],
                        lines: [],
                        mapName: "${name}",
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

            function printCoords(coords, index){
                // TODO: Add different modes
                calYaw(coords);
                for (let i = 0; i < coords.length; i++) {
                    console.log(coords[i].toString());
                }

                var tableIndex = index + 2;
                if (tableIndex === pTable.rows.length){
                    var tr = pTable.insertRow(tableIndex);
                    var cell0 = tr.insertCell(0);
                    var cell1 = tr.insertCell(1);
                    var cell2 = tr.insertCell(2);
                    var cell3 = tr.insertCell(3);
                }else{
                    var tr = pTable.rows[tableIndex];
                    var cell0 = tr.cells[0];
                    var cell1 = tr.cells[1];
                    var cell2 = tr.cells[2];
                    var cell3 = tr.cells[3];
                    cell3.removeChild(cell3.childNodes[0]);
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

                var element = document.createElement("input");
                element.type = "text";
                element.name = "pnameTextbox";
                cell3.appendChild(element);
                element.value = coords[index].name;
                console.log("===");

                element.addEventListener('input', updateValue);

                function updateValue() {
                    let button = document.createElement("button");
                    button.innerText = "save";
                    if (tr.cells.length !== 5){
                        var cell4 = tr.insertCell(4);
                        cell4.appendChild(button);
                        button.addEventListener("click", makeChange);
                    }else {
                        var cell4 = tr.cells[4]
                    }

                    function makeChange() {
                        console.log(element.value);
                        coords[index].name = element.value;
                        tr.removeChild(tr.cells[4]);

                    }
                }
            }

            (function() {
                var httpRequest;
                document.getElementById("submitPoints").addEventListener('click', makeRequest);

                function makeRequest() {

                    httpRequest = new XMLHttpRequest();

                    if (!httpRequest) {
                        alert('Giving up :( Cannot create an XMLHTTP instance');
                        return false;
                    }
                    httpRequest.onreadystatechange = alertContents;
                    httpRequest.open('POST', 'https://0.0.0.0/test.html/gs-robot/cmd/generate_graph_path');
                    httpRequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8')
                    httpRequest.send(generateResultJSON());

                    console.log(httpRequest);
                }

                function alertContents() {
                    if (httpRequest.readyState === XMLHttpRequest.DONE) {
                        if (httpRequest.status === 200) {
                            alert(httpRequest.responseText);
                        } else {
                            alert('There was a problem with the request.');
                        }
                    }
                }
            })();

            var radios = document.querySelectorAll('input[name="ptype"]');
            for (const radio of radios) {
                    radio.addEventListener("change", function () {
                        stage.removeAllEventListeners();
                        registerMouseHandlers();
                    })
            }
        }


    </script>

</head>
<body onload = "init()">
<h1>Simple Map Example</h1>

<form>
    <p>Please choose point type</p>
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
<p id="points"></p>
<table id="ptable">
    <thead>
        <tr>
            <th colspan="4">已标记点</th>
        </tr>
        <tr>
            <th>类型</th>
            <th>坐标</th>
            <th>旋转角</th>
            <th>名字</th>
        </tr>
    </thead>
    <tbody>
    </tbody>
</table>
<button id="submitPoints" type="button">
    提交
</button>

</button>
</body>
</html>
