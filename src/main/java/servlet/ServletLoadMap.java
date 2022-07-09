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

            request.setAttribute("json", "{\n" +
                    "      \"carpets\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"carpetsWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"decelerations\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"decelerationsWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"displays\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"displaysWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"highlight\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"highlightWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"obstacles\":{\n" +
                    "         \"circles\":[\n" +
                    "            {\n" +
                    "                  \"x\":121,\n" +
                    "                  \"y\":-23,\n" +
                    "                  \"r\":5\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":113,\n" +
                    "                  \"y\":-52,\n" +
                    "                  \"r\":2.5\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":13,\n" +
                    "                  \"y\":-2,\n" +
                    "                  \"r\":2.5\n" +
                    "               }\n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            [\n" +
                    "               {\n" +
                    "                  \"x\":21,\n" +
                    "                  \"y\":-23\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":13,\n" +
                    "                  \"y\":-52\n" +
                    "               }\n" +
                    "            ],\n" +
                    "            [\n" +
                    "               {\n" +
                    "                  \"x\":37,\n" +
                    "                  \"y\":-90\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":41,\n" +
                    "                  \"y\":-53\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":63,\n" +
                    "                  \"y\":-5\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":123,\n" +
                    "                  \"y\":-80\n" +
                    "               }\n" +
                    "            ]\n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            [\n" +
                    "               {\n" +
                    "                  \"x\":98,\n" +
                    "                  \"y\":-22\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":89,\n" +
                    "                  \"y\":-55\n" +
                    "               }\n" +
                    "            ]\n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"obstaclesWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            [\n" +
                    "               {\n" +
                    "                  \"x\":-1.1227102611213926,\n" +
                    "                  \"y\":0.042556944116949325\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":-5.0227103192359213,\n" +
                    "                  \"y\":-2.0074430864304311\n" +
                    "               }\n" +
                    "            ],\n" +
                    "            [\n" +
                    "               {\n" +
                    "                  \"x\":7.1772898625582453,\n" +
                    "                  \"y\":-2.6074430953711278\n" +
                    "               },\n" +
                    "               {\n" +
                    "                  \"x\":8.8772898878902193,\n" +
                    "                  \"y\":-4.457443122938276\n" +
                    "               }\n" +
                    "            ]\n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"slopes\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      },\n" +
                    "      \"slopesWorld\":{\n" +
                    "         \"circles\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"lines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polygons\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"polylines\":[\n" +
                    "            \n" +
                    "         ],\n" +
                    "         \"rectangles\":[\n" +
                    "            \n" +
                    "         ]\n" +
                    "      }\n" +
                    "   }");
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("map.jsp");
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) {

    }
}
