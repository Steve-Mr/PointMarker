package servlet;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;

@WebServlet(name = "ServletLoadMap", value = "/ServletLoadMap")
public class ServletLoadMap extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String url = "https://0.0.0.0/gs-robot/data/map_png?map_name=";

        String mapName = request.getParameter("name");
        String mapUrl = "\"http://support.agilex.ai/storage/2021/04-01/YMIT1Bmen7ruIcdXWxDRVpIWIK4krZk2Eee3RFvB.png\"";
        String mapWidth = request.getParameter("width");
        String mapHeight = request.getParameter("height");
        System.out.println(mapName + " " + mapWidth + " " + mapHeight);

        request.setAttribute("url", mapUrl);
        request.setAttribute("width", mapWidth);
        request.setAttribute("height", mapHeight);

        RequestDispatcher dispatcher = request.getRequestDispatcher("map.jsp");
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
