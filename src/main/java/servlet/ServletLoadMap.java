package servlet;

import model.Map;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.util.ArrayList;

@WebServlet(name = "ServletLoadMap", value = "/ServletLoadMap")
public class ServletLoadMap extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

        String url = "https://0.0.0.0/gs-robot/data/map_png?map_name=";

        String mapUrl = "\"http://support.agilex.ai/storage/2021/04-01/YMIT1Bmen7ruIcdXWxDRVpIWIK4krZk2Eee3RFvB.png\"";

        ArrayList<Map> maps = (ArrayList<Map>) request.getSession().getAttribute("maplist");
        System.out.println(maps.get(0).getName());
        Map map = maps.get(Integer.parseInt(request.getParameter("index")));

        request.setAttribute("url", mapUrl);
        request.setAttribute("name", map.getName());
        request.setAttribute("resolution", map.getResolution());
        request.setAttribute("originX", map.getOriginX()*map.getResolution());
        request.setAttribute("originY", map.getOriginY()*map.getResolution());

        RequestDispatcher dispatcher = request.getRequestDispatcher("map.jsp");
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
