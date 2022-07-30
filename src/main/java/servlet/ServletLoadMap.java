package servlet;

import Util.Util;
import model.Map;
import org.json.JSONArray;
import org.json.JSONObject;
import source.LoadMapObj;
import source.LoadPrePoints;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Objects;

@WebServlet(name = "ServletLoadMap", value = "/ServletLoadMap")
public class ServletLoadMap extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

//        String mapUrl = "\"http://support.agilex.ai/storage/2021/04-01/YMIT1Bmen7ruIcdXWxDRVpIWIK4krZk2Eee3RFvB.png\"";

        // 在 session 中保存地图，再次请求地图可能会有改变
        ArrayList<?> maps = (ArrayList<?>) request.getSession().getAttribute("maplist");
        Map map = (Map)maps.get(Integer.parseInt(request.getParameter("index")));

        JSONObject mapObj = new LoadMapObj().getMapObj(Util.URL_GETOBSTACLES + map.getName());
        System.out.println(mapObj.toString());

        JSONArray prePoints = new LoadPrePoints().getPrePoints(Util.URL_GETPOINTS + map.getName() + "&type=");
        System.out.println(Util.URL_GETPOINTS + map.getName() + "&type=");
        System.out.println(prePoints.toString());

        request.setAttribute("url", Util.URL_MAP + map.getName());
        if (map.getName().isEmpty()){
            request.setAttribute("status", false);
        }else {
            request.setAttribute("status", true);
            request.setAttribute("url", Util.URL_MAP +map.getName());
            request.setAttribute("name", map.getName());
            request.setAttribute("resolution", map.getResolution());
            request.setAttribute("originX", map.getOriginX()*map.getResolution());
            request.setAttribute("originY", map.getOriginY()*map.getResolution());

            request.setAttribute("mapObj", mapObj.toString());
            request.setAttribute("prePoints", prePoints.toString());
//            request.setAttribute("mapObj", jsonString);

        }

        RequestDispatcher dispatcher = null;
        if(Objects.equals(request.getParameter("action"), "point")){
            dispatcher = request.getRequestDispatcher("mapPoint.jsp");
        }else if (Objects.equals(request.getParameter("action"), "obstacles")){
            dispatcher = request.getRequestDispatcher("mapObj.jsp");
        }
        
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) {

    }
}
