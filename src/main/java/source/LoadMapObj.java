package source;

import Util.Util;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import model.Map;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.lang.reflect.Type;
import java.net.URI;
import java.net.URL;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Objects;

public class LoadMapObj {
    public JSONObject getMapObj(String url){
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .build();
        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            System.out.println(response.statusCode());
            if (response.statusCode() == 200) {
                String jsonString = response.body();

                JSONObject jsonObject = new JSONObject(jsonString);
                System.out.println(jsonString);
                return new JSONObject(jsonObject.getString("data"));
            }
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
        return new JSONObject("{}");
    }
}
