class Canal {

  //VARIABLES DE INSTANCIA
  private int id;
  private int posY; //posición del canal (para evitar superposición 

  //direcciones E/S
  private String canalInput; 
  private String canalOutput;

  private float saturacion = 9000; //maximo permitido
  private float valor = 0; //normalizada
  private float valorReal = 0; //cruda
  
  //flags
  private boolean send = false;
  private boolean receive = false;
  private Toggle toggleReceive;
  private Toggle toggleSend;

  private Slider sliderSaturacion; //saturacion (probando si funca así)
   
  //dependencias
  private ControlP5 cp5;
  private OscP5 oscControl;
  private NetAddress remote;
  private Chart grafico; //guarda el grafico del canal 
  
  //tecnica y movimiento era una por canal(?
  private Textfield tecnicaField;
  private Textfield movimientoField;

  //CONSTRUCTOR
  Canal(int id, int posY, ControlP5 cp5, OscP5 osc, NetAddress remote) {
    this.id = id;
    this.posY = posY;
    this.canalInput = "/wimumo001/emg/ch" + this.id;
    this.canalOutput = "'' " + this.id + "''";
    this.cp5 = cp5;
    this.oscControl = osc;
    this.remote = remote;
    //println("Canal creado: " + id);

    crearUI();
  }

  //GETTERS
  public float getValor(){
    return this.valor;
  }
  
  public float getValorReal(){
    return this.valorReal;
  }
  
  public String getTecnica() {
    return tecnicaField.getText();
  }

  public String getMovimiento() {
    return movimientoField.getText();
  }
  
  //METODOS
  private void crearUI() {

    cp5.addTextfield("canal" + id + "_Input") //caja de texto
      .setPosition(15, this.posY)
      .setSize(80, 15)
      .setAutoClear(false);

    toggleReceive = cp5.addToggle("receive" + this.id)
      .setPosition(105, this.posY)
      .setSize(50, 15);

    toggleSend = cp5.addToggle("send" + this.id)
      .setPosition(105, this.posY + 45)
      .setSize(50, 15);

    sliderSaturacion = cp5.addSlider("slider_saturacion_" + this.id)
      .setPosition(width/2, this.posY - 15)
      .setRange(1, 9000)
      .setValue(9000);

    grafico = cp5.addChart("grafico" + this.id) //crear grafico
      .setPosition(170, this.posY)
      .setSize(820, 130)
      .setRange(-1, 1)
      .setView(Chart.LINE);

    grafico.addDataSet("data_saturacion_" + this.id);
    grafico.setData("data_saturacion_" + this.id, new float[360]);
    
    // tecnica y movimiento
    tecnicaField = cp5.addTextfield("tecnica_" + id)
      .setPosition(1000, this.posY)
      .setSize(120, 20)
      .setAutoClear(false)
      .setLabel("TEC");

    movimientoField = cp5.addTextfield("movimiento_" + id)
      .setPosition(1000, this.posY + 45)
      .setSize(120, 20)
      .setAutoClear(false)
      .setLabel("MOV");
  }

  public void actualizarGrafico() { 
    grafico.push("data_saturacion_" + this.id, this.valor);
  }

  public void procesarMensaje(OscMessage msg) {
    
    this.receive = toggleReceive.getState();
    this.send = toggleSend.getState();
    
    this.saturacion = sliderSaturacion.getValue(); //para poder cambiar la saturación que no me funcaba 
    if (msg.checkAddrPattern(this.canalInput) && this.receive) {

      this.valorReal = msg.get(0).floatValue();
      this.valor = this.valorReal;

      if (this.valor > this.saturacion) {
        this.valor = this.saturacion;
      }

      this.valor = this.valor / this.saturacion;

      if (this.send) {
        OscMessage nuevo = new OscMessage(this.canalOutput);
        nuevo.add(this.valor);
        oscControl.send(nuevo, remote);
      }
    }
  }

}
