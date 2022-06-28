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
        String mapResolution = request.getParameter("resolution");
        System.out.println(mapResolution);

    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
