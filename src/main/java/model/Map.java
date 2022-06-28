package model;

public class Map {

    String dataFileName;
    int id;
    int gridHeight;
    int gridWidth;
    float originX;
    float originY;
    double resolution;
    String name;
    String pgmFileName;
    String pngFileName;
    String yamlFileName;

    public Map(){}

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

    public int getGridHeight() {
        return gridHeight;
    }

    public void setGridHeight(int gridHeight) {
        this.gridHeight = gridHeight;
    }

    public int getGridWidth() {
        return gridWidth;
    }

    public void setGridWidth(int gridWidth) {
        this.gridWidth = gridWidth;
    }

    public float getOriginX() {
        return originX;
    }

    public void setOriginX(float originX) {
        this.originX = originX;
    }

    public float getOriginY() {
        return originY;
    }

    public void setOriginY(float originY) {
        this.originY = originY;
    }

    public double getResolution() {
        return resolution;
    }

    public void setResolution(double resolution) {
        this.resolution = resolution;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
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
}
