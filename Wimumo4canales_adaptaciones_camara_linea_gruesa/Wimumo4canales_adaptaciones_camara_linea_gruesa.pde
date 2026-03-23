import processing.video.*; //Libreria de la camara para processing 4)
import controlP5.*; //Crea interfaz gráfica dentro de Sketch
import oscP5.*; //Envia-recibe mje por Open Sound Control
import netP5.*; //Comunicación e/ disp

// comunicacion
private OscP5 oscControl; //comunicacion osc
private NetAddress myRemoteLocation; //dir remota
private String ipInput = "127.0.0.1"; // IP LOCAL (CAMBIAR)
private int puertoInput = 12000;

// camara
private Capture camara;
private int posXCamara, posYCamara;

// UI
private ControlP5 cp5; //interfaz

// mis canales 
private Canal[] canales;

// grabacion
private boolean grabar = false; //esto es para grabar CSV
private Table table; //tabla CSV
private String sessionName;

// tiempo
private int intervalTime = 83; //porque 83?
private int prevTime = 0;

void setup() {
  size(1650, 902);
  pixelDensity(1); //me tiro un warning así que lo agrego
  frameRate(40);
  noStroke();

  inicializarTiempo();
  inicializarSesion();
  inicializarCamara();
  inicializarTabla();
  inicializarOSC();
  inicializarCanales();
  inicializarUI();
  
}

// METODOS
void oscEvent(OscMessage msg) {
  for (Canal c : canales) {
    c.procesarMensaje(msg);
  }
}

void draw() {
  background(0);
  // ---- SIMULACION TEMPORAL ----
  for (int i = 0; i < canales.length; i++) {
    OscMessage fake = new OscMessage("/wimumo001/emg/ch" + (i+1));
    fake.add(random(0, 9000));
    canales[i].procesarMensaje(fake);
  }
  // -----------------------------
  for (Canal c : canales) {
    c.actualizarGrafico();
  }
  if (grabar && millis() - prevTime > intervalTime) {
    prevTime = millis();
    guardarDatos();
  }
}

private void guardarDatos() {

  TableRow fila = table.addRow();

  fila.setString("hora", str(millis()));

  for (int i = 0; i < canales.length; i++) {
    int n = i + 1;

    fila.setFloat("v" + n, canales[i].getValor());
    fila.setFloat("v" + n + " crudo", canales[i].getValorReal());

    fila.setString("tecnica" + n, canales[i].getTecnica());
    fila.setString("mov" + n, canales[i].getMovimiento());
  }
}

void controlEvent(ControlEvent theEvent) {

  if (theEvent.isFrom("GRABAR")) {

    grabar = theEvent.getController().getValue() == 1;

    if (!grabar) {
      saveTable(table, sessionName + ".csv");
      println("CSV guardado: " + sessionName);
    }
  }
}

private void inicializarTiempo() {
  this.prevTime = millis();
}

private String generarNombreSesion() {
  return year()+"_"+month()+"_"+day()+"-"+hour()+"_"+minute()+"_"+second()+"_"+(millis()%1000);
}

private void inicializarSesion() {
  this.sessionName = generarNombreSesion();
}

private void inicializarTabla() {
  table = new Table();
  table.addColumn("hora");

  for (int i = 1; i <= 4; i++) {
    table.addColumn("v" + i);
  }

  for (int i = 1; i <= 4; i++) {
    table.addColumn("v" + i + " crudo");
  }

  for (int i = 1; i <= 4; i++) {
    table.addColumn("tecnica" + i);
    table.addColumn("mov" + i);
  }
}

private void inicializarCamara() {
  camara = new Capture(this, 640, 480);
  camara.start();
  posXCamara = 1000;
  posYCamara = 110;
}

private void inicializarOSC() {
  cp5 = new ControlP5(this);
  oscControl = new OscP5(this, 3333);
  myRemoteLocation = new NetAddress(ipInput, puertoInput);
  //ipInput = oscControl.ip();
}

private void inicializarCanales() {
  canales = new Canal[4];
  for (int i = 0; i < 4; i++) {
    int posY = 50 + i * 150;
    canales[i] = new Canal(i + 1, posY, cp5, oscControl, myRemoteLocation);
  }
}

// UI
private void inicializarUI() {
  // Botón para grabar (el resto esta en la clase canal
  cp5.addToggle("GRABAR")
    .setPosition(1130, 500)
    .setSize(100, 80);
}
