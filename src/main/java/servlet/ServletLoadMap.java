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

//        String url = "https://0.0.0.0/gs-robot/data/map_png?map_name=";

        String mapUrl = "\"http://support.agilex.ai/storage/2021/04-01/YMIT1Bmen7ruIcdXWxDRVpIWIK4krZk2Eee3RFvB.png\"";

        // 在 session 中保存地图，再次请求地图可能会有改变
        ArrayList<?> maps = (ArrayList<?>) request.getSession().getAttribute("maplist");
        Map map = (Map)maps.get(Integer.parseInt(request.getParameter("index")));

//        request.setAttribute("url", url + map.getName());
        if (map.getName().isEmpty()){
            request.setAttribute("status", false);
        }else {
            request.setAttribute("status", true);
            request.setAttribute("url", mapUrl);
            request.setAttribute("name", map.getName());
            request.setAttribute("resolution", map.getResolution());
            request.setAttribute("originX", map.getOriginX()*map.getResolution());
            request.setAttribute("originY", map.getOriginY()*map.getResolution());
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("map.jsp");
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) {

    }
}
