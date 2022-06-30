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

        function init() {
            console.log("init...");

            var image_url = ${url};
            var canvas = document.getElementById("map");
            var stage = new createjs.Stage(canvas);
            var bitmap = new createjs.Bitmap(image_url);

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
                        document.getElementById("points").innerHTML="";
                        for (let i = 0; i < coords.length; i++) {
                            document.getElementById("points").innerHTML += coords[i].toString() + "<br/>";
                            console.log(coords[i].toString());
                        }
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
                pointSize: 10,
                lineSize: 0.5
            });

            console.log(polygon.pointColor);

            // Hack
            // in source code : this.fillColor = options.pointColor || createjs.Graphics.getRGB(0, 255, 0, 0.33);
            polygon.fillColor = createjs.Graphics.getRGB(100, 100, 255, 0);

            // Add the polygon to the viewer
            // stage.addChild(polygon);

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
                                var coord = pos.x.toString() + ", " + pos.y.toString();
                                coords.push(coord);
                                // document.getElementById("points").innerText = pos.x;
                                // for (var index = 0; index < polygon.pointContainer.getNumChildren(); index++) {
                                //     var markerPoints = polygon.pointContainer.getChildAt(index);
                                //     console.log(markerPoints.x, markerPoints.y);
                                //     // document.getElementById("points").innerText = markerPoints.x;
                                // }
                                for(var i = 0; i < coords.length; i++) console.log(coords[i].toString());
                                // document.getElementById("points").innerText = coords.toString();
                                document.getElementById("points").innerHTML += coord.toString() + "<br/>";
                                console.log('===');
                            }
                            clickedPolygon = false;
                        }
                        mouseDown = false;
                    }
                });
            }

            registerMouseHandlers();
            stage.x = typeof stage.x_prev_shift !== 'undefined' ? stage.x_prev_shift : stage.x;
            stage.y = typeof stage.y_prev_shift !== 'undefined' ? stage.y_prev_shift : stage.y;
            stage.scaleX = 800 / ${width};
            stage.scaleY = 800 / ${height};

        }

    </script>

</head>
<body onload = "init()">
<h1>Simple Map Example</h1>

<canvas id="map" width="800" height="800" style="border:1px solid #f11010;"></canvas>
<p id="points"></p>
</body>
</html>
