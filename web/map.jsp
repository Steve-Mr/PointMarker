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

                this.type = options.type || 6;
                this.x = options.x;
                this.y = options.y;
                this.yaw = options.yaw || 0.0;
            }

            toString(){
                return this.type.toString() + " | "
                    + this.x.toString() + ", "
                    + this.y.toString() + ", "
                    + this.yaw.toString();
            }
        }

        function init() {
            console.log("init...");

            var image_url = ${url};
            var canvas = document.getElementById("map");
            var stage = new createjs.Stage(canvas);
            var bitmap = new createjs.Bitmap(image_url);
            var resolution = ${resolution};
            var originX = ${originX};
            var originY = ${originY};

            var radioPType = document.getElementsByName("ptype");

            var pointsBlock = document.getElementById("points");

            bitmap.scaleX = resolution;
            bitmap.scaleY = resolution;

            var coords = new Array();

            console.log(image_url.toString());
            stage.addChild(bitmap);
            createjs.Ticker.framerate = 30;
            createjs.Ticker.addEventListener("tick", stage);

            console.log("stage.scaleX before: " + stage.scaleX.toString() + ", stage.scaleY before: " + stage.scaleY.toString());

            bitmap.image.onload = function () {
                // restore to values before shifting, if occurred
                stage.x = typeof stage.x_prev_shift !== 'undefined' ? stage.x_prev_shift : stage.x;
                stage.y = typeof stage.y_prev_shift !== 'undefined' ? stage.y_prev_shift : stage.y;

                console.log(bitmap.getBounds().width.toString());

                // save scene scaling
                stage.scaleX = 800 / (bitmap.image.width * resolution);
                stage.scaleY = 800 / (bitmap.image.height * resolution);

                stage.update();
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
                        printCoords(pointsBlock, coords);
                    }
                    else {
                        selectedPointIndex = index;
                    }
                }
                clickedPolygon = true;
            };

            var lineCallBack = function (type, event, index) {
                if (type === 'mousedown') {
                    if (event.nativeEvent.ctrlKey === true) {
                        polygon.splitLine(index);
                        coords = []
                        for(var i = 0; i < polygon.pointContainer.getNumChildren(); i ++){
                            var pos = polygon.pointContainer.getChildAt(i);
                            coords.push(getActualCoord(pos));
                        }
                        printCoords(pointsBlock, coords);
                    }
                }
                clickedPolygon = true;
            }

            // Create the polygon
            var polygon = new ROS2D.PolygonMarker({
                pointColor: createjs.Graphics.getRGB(255, 0, 0, 0.66),
                lineColor: createjs.Graphics.getRGB(100, 100, 255, 1),
                pointCallBack: pointCallBack,
                lineCallBack: lineCallBack,
                pointSize: bitmap.image.width * resolution * 0.01,
                lineSize: bitmap.image.width * resolution * 0.01 * 0.5
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
                                coords[selectedPointIndex] = getActualCoord(pos);
                                printCoords(pointsBlock, coords);
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

                                printCoords(pointsBlock, coords);
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
                    coords[index].yaw =  Math.atan2(coord2.y - coord1.y, coord2.x - coord1.x).toFixed(2);
                    console.log((coord2.y - coord1.y).toString() + ", " + (coord2.x - coord1.x).toString());
                }
            }

            function printCoords(block, coords){
                calYaw(coords);
                block.innerHTML="";
                for (let i = 0; i < coords.length; i++) {
                    block.innerHTML += coords[i].toString() + "<br/>";
                    console.log(coords[i].toString());
                }
                console.log("===");
            }

            var radios = document.querySelectorAll('input[name="ptype"]');
            for (const radio of radios) {
                    radio.addEventListener("change", function () {
                        console.log("radio: " + document.querySelector('input[name="ptype"]:checked').value.toString());
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
</body>
</html>
