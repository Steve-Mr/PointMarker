package servlet;

import model.Map;
import source.LoadMapList;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ServletLoadMapList", urlPatterns = "/maplist")
public class ServletLoadMapList extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        List<Map> maps = new LoadMapList().getMapList();
        request.setAttribute("maps", maps);
        RequestDispatcher dispatcher = request.getRequestDispatcher("maplist.jsp");
        dispatcher.forward(request,response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
