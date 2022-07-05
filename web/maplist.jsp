<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Created by IntelliJ IDEA.
  User: maary
  Date: 2022/6/28
  Time: 下午3:12
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Title</title>

    <script>
        function saveMaps() {
            <% request.getSession().setAttribute("maplist", request.getAttribute("maps"));%>
            // 加载后保存地图列表到 session
        }
    </script>

</head>
<body onload="saveMaps()">
<h1>Map List</h1>
<table>
    <tr>
        <th>Id</th>
        <th>Name</th>
    </tr>

    <c:forEach var="map" items="${requestScope.maps}" varStatus="loop">
        <tr>
            <td>${map.id}</td>
            <td> <a href="ServletLoadMap?index=${loop.index}">${map.name}</a></td>
        </tr>
    </c:forEach>
</table>
</body>
</html>
