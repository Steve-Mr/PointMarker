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
        // change coord of points after moving it
        // 坐标系
        // return 坐标点

        function init() {
            console.log("init...");

            var image_url = ${url};
            var canvas = document.getElementById("map");
            var stage = new createjs.Stage(canvas);
            var bitmap = new createjs.Bitmap(image_url);
            var resolution = ${resolution};

            var pointsBlock = document.getElementById("points");

            bitmap.scaleX = resolution;
            bitmap.scaleY = resolution;

            var coords = new Array();

            console.log(image_url.toString());
            stage.addChild(bitmap);
            createjs.Ticker.framerate = 30;
            createjs.Ticker.addEventListener("tick", stage);

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
                        rePrintCoords(pointsBlock, coords);
                        console.log('===');
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
                            coords.push(getActualCoord(pos, bitmap, resolution));
                        }
                        rePrintCoords(pointsBlock, coords);
                        console.log('===');
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
            // TODO: dynamic adjust point size and line size

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
                                coords[selectedPointIndex] = getActualCoord(pos, bitmap, resolution);
                                rePrintCoords(pointsBlock, coords);
                                console.log('===');
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
                                var coord = getActualCoord(pos, bitmap, resolution);
                                // TODO: 查看相关功能和函数的影响
                                coords.push(coord);

                                for(var i = 0; i < coords.length; i++) console.log(coords[i].toString());
                                pointsBlock.innerHTML += coord.toString() + "<br/>";
                                console.log('===');
                            }
                            clickedPolygon = false;
                        }
                        mouseDown = false;
                    }
                });
            }

            registerMouseHandlers();
            // restore to values before shifting, if occurred
            stage.x = typeof stage.x_prev_shift !== 'undefined' ? stage.x_prev_shift : stage.x;
            stage.y = typeof stage.y_prev_shift !== 'undefined' ? stage.y_prev_shift : stage.y;

            // save scene scaling
            stage.scaleX = 800 / (bitmap.image.width * resolution);
            stage.scaleY = 800 / (bitmap.image.height * resolution);
            stage.update();

            function getActualCoord(pos, bitmap, resolution){
                this.pos = pos;
                this.bitmap = bitmap;
                this.resolution = resolution;
                return Math.round(this.pos.x).toString() + ", "
                    + Math.round(this.pos.y+(this.bitmap.image.height * this.resolution)).toString();
            }

            function rePrintCoords(block, coords){
                block.innerHTML="";
                for (let i = 0; i < coords.length; i++) {
                    block.innerHTML += coords[i].toString() + "<br/>";
                    console.log(coords[i].toString());
                }
            }
        }

    </script>

</head>
<body onload = "init()">
<h1>Simple Map Example</h1>

<canvas id="map" width="800" height="800" style="border:1px solid #f11010;"></canvas>
<p id="points"></p>
</body>
</html>
