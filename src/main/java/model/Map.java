package model;

public class Map {

    String createdAt;
    String dataFileName;
    int id;
    String name;
    String obstacleFileName;
    String pgmFileName;
    String pngFileName;
    String yamlFileName;

    mapInfo mapInfo = new mapInfo();

    static class mapInfo {
        int gridHeight;
        int gridWidth;
        float originX = 0;
        float originY = 0;
        double resolution = 1.0;
    }

    public Map(){}

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getDataFileName() {
        return dataFileName;
    }

    public void setDataFileName(String dataFileName) {
        this.dataFileName = dataFileName;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getObstacleFileName() {
        return obstacleFileName;
    }

    public void setObstacleFileName(String obstacleFileName) {
        this.obstacleFileName = obstacleFileName;
    }

    public String getPgmFileName() {
        return pgmFileName;
    }

    public void setPgmFileName(String pgmFileName) {
        this.pgmFileName = pgmFileName;
    }

    public String getPngFileName() {
        return pngFileName;
    }

    public void setPngFileName(String pngFileName) {
        this.pngFileName = pngFileName;
    }

    public String getYamlFileName() {
        return yamlFileName;
    }

    public void setYamlFileName(String yamlFileName) {
        this.yamlFileName = yamlFileName;
    }

    public int getGridHeight() {
        return mapInfo.gridHeight;
    }

    public void setGridHeight(int gridHeight) {
        mapInfo.gridHeight = gridHeight;
    }

    public int getGridWidth() {
        return mapInfo.gridWidth;
    }

    public void setGridWidth(int gridWidth) {
        mapInfo.gridWidth = gridWidth;
    }

    public float getOriginX() {
        return mapInfo.originX;
    }

    public void setOriginX(float originX) {
        mapInfo.originX = originX;
    }

    public float getOriginY() {
        return mapInfo.originY;
    }

    public void setOriginY(float originY) {
        mapInfo.originY = originY;
    }

    public double getResolution() {
        return mapInfo.resolution;
    }

    public void setResolution(double resolution) {
        mapInfo.resolution = resolution;
    }
}
