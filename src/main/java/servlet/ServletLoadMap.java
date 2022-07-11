package servlet;

import model.Map;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.util.ArrayList;

@WebServlet(name = "ServletLoadMap", value = "/ServletLoadMap")
public class ServletLoadMap extends HttpServlet {

    String jsonString = "{\n" +
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
            "         \"polygons\":[\n" +
            "            \n" +
            "         ],\n" +
            "         \"polylines\":[\n" +
            "            [\n" +
            "               {\n" +
            "                  \"x\":6,\n" +
            "                  \"y\":51\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":8,\n" +
            "                  \"y\":52\n" +
            "               }\n" +
            "            ],\n" +
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
            "                  \"x\":72,\n" +
            "                  \"y\":107,\n" +
            "                  \"r\":5\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":87,\n" +
            "                  \"y\":66,\n" +
            "                  \"r\":2.5\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":77,\n" +
            "                  \"y\":79,\n" +
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
            "                  \"x\":106,\n" +
            "                  \"y\":51\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":108,\n" +
            "                  \"y\":52\n" +
            "               }\n" +
            "            ],\n" +
            "            [\n" +
            "               {\n" +
            "                  \"x\":9,\n" +
            "                  \"y\":59\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":13,\n" +
            "                  \"y\":57\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":19,\n" +
            "                  \"y\":59\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":18,\n" +
            "                  \"y\":63\n" +
            "               }\n" +
            "            ]\n" +
            "         ],\n" +
            "         \"rectangles\":[\n" +
            "            [\n" +
            "               {\n" +
            "                  \"x\":86,\n" +
            "                  \"y\":35\n" +
            "               },\n" +
            "               {\n" +
            "                  \"x\":93,\n" +
            "                  \"y\":26\n" +
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
            "                  \"x\":50.1772898625582453,\n" +
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
            "   }";
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

            request.setAttribute("json", jsonString);
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("mapObj.jsp");
        dispatcher.forward(request, response);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) {

    }
}
