<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Created by IntelliJ IDEA.
  User: maary
  Date: 2022/6/28
  Time: 下午3:12
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
    <h1>Map List</h1>
    <table border="2" width="70%" cellpadding="2">
        <tr>
            <th>Id</th>
            <th>Name</th>
        </tr>
        <c:forEach var="map" items="${maps}">
            <tr>
                <td>${map.id}</td>
                <td> <a href="ServletLoadMap?name=${map.name}?&&resolution=${map.resolution}">${map.name}</a></td>
            </tr>
        </c:forEach>
    </table>
</head>
<body>

</body>
</html>
