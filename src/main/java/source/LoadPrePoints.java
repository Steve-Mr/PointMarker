package source;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class LoadPrePoints {
    public JSONArray getPrePoints(String url){
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
                return new JSONArray(jsonObject.getJSONArray("data"));

//                return new JSONObject(jsonObject.getJSONArray("data"));
            }
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
        return new JSONArray("[]");
    }
}
