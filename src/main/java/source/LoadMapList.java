package source;

import model.Map;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;

public class LoadMapList {

    String url = "https://0.0.0.0/gs-robot/data/maps";
    String charset = java.nio.charset.StandardCharsets.UTF_8.name();

    public List<Map> getMapList() {
        System.out.println("starting process");

        ArrayList<Map> mapList = new ArrayList<>();

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .build();
        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                String jsonString = response.body();
                JSONObject jsonObject = new JSONObject(jsonString);
                if (jsonObject.getString("msg") == "successed") {
                    JSONArray mapArray = jsonObject.getJSONArray("data");
                    for (int i = 0; i < mapArray.length(); i++) {
                        Map map = new Map();
                        JSONObject mapObj = mapArray.getJSONObject(i);
                        map.setDataFileName(mapObj.getString("dataFileName"));
                        map.setId(Integer.parseInt(mapObj.getString("id")));
                        JSONObject mapInfo = mapObj.getJSONObject("mapInfo");
                        map.setGridHeight(Integer.parseInt(mapInfo.getString("gridX")));
                        map.setGridWidth(Integer.parseInt(mapInfo.getString("gridY")));
                        map.setOriginX(Float.parseFloat(mapInfo.getString("originX")));
                        map.setOriginY(Float.parseFloat(mapInfo.getString("originY")));
                        map.setResolution(Double.parseDouble(mapInfo.getString("resolution")));
                        map.setName(mapObj.getString("name"));
                        map.setPgmFileName(mapObj.getString("pgmFileName"));
                        map.setPngFileName(mapObj.getString("pngFileName"));
                        map.setYamlFileName(mapObj.getString("yamlFileName"));

                        mapList.add(map);
                    }
                }

            }
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }


        // will be deleted
        for (int i = 0; i < 5; i++) {
            Map map = new Map();
            map.setDataFileName("name"+i);
            map.setId(i);
            map.setGridHeight(300);
            map.setGridWidth(300);
            map.setOriginX((float) 3.25);
            map.setOriginY((float) 3.2);
            map.setResolution(0.025);
            map.setName("name"+i);
            map.setPgmFileName("name");
            map.setPngFileName("name");
            map.setYamlFileName("name");

            mapList.add(map);
            System.out.println(map);
        }

        return mapList;
    }
}
