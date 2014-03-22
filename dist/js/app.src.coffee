class @ShaderPassBase
  constructor: (initialValues) ->
    @enabled = true
    @uniforms = THREE.UniformsUtils.clone @findUniforms(@fragmentShader)
    for key, value of initialValues
      @uniforms[key].value = value

    @material = new THREE.ShaderMaterial {
      uniforms: @uniforms
      vertexShader: @vertexShader
      fragmentShader: @fragmentShader
    }

    @enabled = true
    @renderToScreen = false
    @needsSwap = true

    @camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
    @scene  = new THREE.Scene();

    @quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), null)
    @scene.add @quad

  render: (renderer, writeBuffer, readBuffer, delta) ->
    @update?()
    if !@enabled
      writeBuffer = readBuffer
      return
    @uniforms['uTex'].value = readBuffer
    @uniforms['uSize'].value.set(readBuffer.width, readBuffer.height)
    @quad.material = @material
    if @renderToScreen
      renderer.render @scene, @camera
    else
      renderer.render @scene, @camera, writeBuffer, false

  standardUniforms: {
    uTex: {type: 't', value: null}
    uSize: {type: 'v2', value: new THREE.Vector2( 256, 256 )}
  }
  
  vertexShader: """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
  """

  findUniforms: (shader) ->
    lines = shader.split("\n")
    uniforms = {}
    for line in lines
      if (line.indexOf("uniform") == 0)
        tokens = line.split(" ")
        name = tokens[2].substring(0, tokens[2].length - 1)
        uniforms[name] = @typeToUniform tokens[1]
    uniforms

  typeToUniform: (type) ->
    switch type
      when "float" then {type: "f", value: 0}
      when "vec2" then {type: "v2", value: new THREE.Vector2}
      when "vec3" then {type: "v3", value: new THREE.Vector3}
      when "vec4" then {type: "v4", value: new THREE.Vector4}
      when "bool" then {type: "i", value: 0}
      when "sampler2D" then {type: "t", value: null}


class Composition extends Backbone.Model
  constructor: () ->
    super()
    @generateThumbnail()

  generateThumbnail: () ->
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, clearAlpha: 0, transparent: true})
    renderer.setSize(140, 90)
    @setup renderer
    renderer.render @scene, @camera
    @thumbnail = document.createElement('img')
    @thumbnail.src = renderer.domElement.toDataURL()
    @trigger "thumbnail-available"


class GLSLComposition extends Composition
  setup: (@renderer) ->
    @uniforms = THREE.UniformsUtils.clone @findUniforms(@fragmentShader)
    @material = new THREE.ShaderMaterial {
      uniforms: @uniforms
      vertexShader: @vertexShader
      fragmentShader: @fragmentShader
    }

    @enabled = true
    @renderToScreen = false
    @needsSwap = true

    @camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
    @scene = new THREE.Scene

    @quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), null)
    @quad.material = @material
    @scene.add @quad

  vertexShader: """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
  """

  findUniforms: (shader) ->
    lines = shader.split("\n")
    uniforms = {}
    for line in lines
      if (line.indexOf("uniform") == 0)
        tokens = line.split(" ")
        name = tokens[2].substring(0, tokens[2].length - 1)
        uniforms[name] = @typeToUniform tokens[1]
    uniforms

  typeToUniform: (type) ->
    switch type
      when "float" then {type: "f", value: 0}
      when "vec2" then {type: "v2", value: new THREE.Vector2}
      when "vec3" then {type: "v3", value: new THREE.Vector3}
      when "vec4" then {type: "v4", value: new THREE.Vector4}
      when "bool" then {type: "i", value: 0}
      when "sampler2D" then {type: "t", value: null}

class CircleGrower extends GLSLComposition
  setup: (@renderer) ->
    super(@renderer)
    @uniforms.circleSize.value = 300

  update: () ->
    @uniforms['uSize'].value.set(@renderer.domElement.width, @renderer.domElement.height)
    @uniforms['time'].value += 1
  
  fragmentShader: """
    uniform vec2 uSize;
    varying vec2 vUv;
    uniform float circleSize;
    uniform float time;
    void main (void)
    {
      vec2 pos = mod(gl_FragCoord.xy, vec2(circleSize)) - vec2(circleSize / 2.0);
      float dist = sqrt(dot(pos, pos));
      dist = mod(dist + time * -1.0, circleSize + 1.0) * 2.0;
      
      gl_FragColor = (sin(dist / 25.0) > 0.0) 
          ? vec4(.90, .90, .90, 1.0)
          : vec4(0.0);
    }
  """
class SphereSphereComposition extends Composition
  setup: (@renderer) ->
    @scene = new THREE.Scene
    @camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
    @camera.position.z = 1000;
    @origin = new THREE.Vector3 0, 0, 0
    @group = new THREE.Object3D
    @scene.add @group
    @sphereGeometry = new THREE.SphereGeometry(10, 32, 32)
    @sphereMaterial = new THREE.MeshPhongMaterial({
      transparent: false
      opacity: 1
      color: 0xDA8258
      specular: 0xD67484
      shininess: 10
      ambient: 0xAAAAAA
      shading: THREE.FlatShading
    })
    for size in [400]#[200, 300, 400]
      res = 50
      skeleton = new THREE.SphereGeometry(size, res, res)
      for vertex in skeleton.vertices
        @addCube @group, vertex

    light = new THREE.SpotLight 0xFFFFFF
    light.position.set 1000, 1000, 300
    @scene.add light

    light = new THREE.AmbientLight 0x222222
    @scene.add light

    ambient = new THREE.PointLight( 0x444444, 1, 10000 );
    ambient.position.set 500, 500, 500
    @scene.add ambient

    ambient = new THREE.PointLight( 0x444444, 1, 10000 );
    ambient.position.set -500, 500, 500
    @scene.add ambient
  update: () ->
    @group.rotation.y += 0.001

  addCube: (group, position) ->
    mesh = new THREE.Mesh @sphereGeometry, @sphereMaterial
    mesh.position = position
    mesh.lookAt @origin
    @group.add mesh


class VideoComposition extends Backbone.Model
  constructor: (@videoFile) ->
    super()
    if @videoFile
      videoTag = document.createElement('video')
      document.body.appendChild videoTag
      videoTag.src = URL.createObjectURL(@videoFile)
      videoTag.addEventListener 'loadeddata', (e) =>
        videoTag.currentTime = videoTag.duration / 2
        canvas = document.createElement('canvas')
        canvas.width = videoTag.videoWidth
        canvas.height = videoTag.videoHeight
        context = canvas.getContext('2d')
        f = () =>
          if videoTag.readyState != videoTag.HAVE_ENOUGH_DATA
            setTimeout f, 100
            return
          context.drawImage videoTag, 0, 0
          @thumbnail = document.createElement('img')
          @thumbnail.src = canvas.toDataURL()
          videoTag.pause()
          videoTag = null
          @trigger "thumbnail-available"
        setTimeout f, 100


  setup: (@renderer) ->
    @enabled = true
    @renderToScreen = false
    @needsSwap = true

    @camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
    @scene = new THREE.Scene

    @video = document.createElement 'video'
    if @videoFile
      @video.src = URL.createObjectURL(@videoFile)
    else
      @video.src = "assets/timescapes.mp4"
    @video.load()
    @video.play()
    @video.volume = 0
    window.video = @video
    @video.addEventListener 'loadeddata', () =>
      console.log @video.videoWidth
      @videoImage = document.createElement 'canvas'
      @videoImage.width = @video.videoWidth
      @videoImage.height = @video.videoHeight

      @videoImageContext = @videoImage.getContext('2d')
      @videoTexture = new THREE.Texture(@videoImage)
      @videoTexture.minFilter = THREE.LinearFilter;
      @videoTexture.magFilter = THREE.LinearFilter;
      @material = new THREE.MeshBasicMaterial(map: @videoTexture)


      @quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), @material)
      @scene.add @quad

  update: () ->
    if @videoTexture
      @videoImageContext.drawImage @video, 0, 0
      @videoTexture.needsUpdate = true
class BlurPass extends ShaderPassBase
  fragmentShader: """
    uniform float blurX;
    uniform vec2 uSize;
    varying vec2 vUv;
    uniform sampler2D uTex;

    const float blurSize = 1.0/512.0; // I've chosen this size because this will result in that every step will be one pixel wide if the RTScene texture is of size 512x512
     
    void main(void)
    {
       vec4 sum = vec4(0.0);
     
       // blur in y (vertical)
       // take nine samples, with the distance blurSize between them
       sum += texture2D(uTex, vec2(vUv.x - 4.0*blurX, vUv.y)) * 0.05;
       sum += texture2D(uTex, vec2(vUv.x - 3.0*blurX, vUv.y)) * 0.09;
       sum += texture2D(uTex, vec2(vUv.x - 2.0*blurX, vUv.y)) * 0.12;
       sum += texture2D(uTex, vec2(vUv.x - blurX, vUv.y)) * 0.15;
       sum += texture2D(uTex, vec2(vUv.x, vUv.y)) * 0.16;
       sum += texture2D(uTex, vec2(vUv.x + blurX, vUv.y)) * 0.15;
       sum += texture2D(uTex, vec2(vUv.x + 2.0*blurX, vUv.y)) * 0.12;
       sum += texture2D(uTex, vec2(vUv.x + 3.0*blurX, vUv.y)) * 0.09;
       sum += texture2D(uTex, vec2(vUv.x + 4.0*blurX, vUv.y)) * 0.05;
     
       gl_FragColor = sum;
    }
  """

class InvertPass extends ShaderPassBase
  name: "Invert"
  uniformValues: [
    {uniform: "amount", name: "Invert Amount", start: 0, end: 1}
  ]
  fragmentShader: """
    uniform float amount;
    uniform vec2 uSize;
    varying vec2 vUv;
    uniform sampler2D uTex;

    void main (void)
    {
        vec4 color = texture2D(uTex, vUv);
        color = (1.0 - amount) * color + (amount) * (1.0 - color);
        gl_FragColor = vec4(color.rgb, color.a);
    }
  """

class MirrorPass extends ShaderPassBase
  name: "Mirror"
  fragmentShader: """
    uniform vec2 uSize;
    varying vec2 vUv;
    uniform sampler2D uTex;

    void main (void)
    {
      vec4 color = texture2D(uTex, vUv);
      vec2 flipPos = vec2(0.0);
      flipPos.x = 1.0 - vUv.x;
      flipPos.y = vUv.y;
      gl_FragColor = color + texture2D(uTex, flipPos);
    }
  """

class ShroomPass extends ShaderPassBase
  constructor: () ->
    super amp: 0, StartRad: 0, freq: 10

  name: "Wobble"
  uniformValues: [
    {uniform: "amp", name: "Wobble Amount", start: 0, end: 0.05}
  ]
  update: () ->
    @uniforms.StartRad.value += 0.01
    
  fragmentShader: """
    // Constants
    const float C_PI    = 3.1415;
    const float C_2PI   = 2.0 * C_PI;
    const float C_2PI_I = 1.0 / (2.0 * C_PI);
    const float C_PI_2  = C_PI / 2.0;

    uniform float StartRad;
    uniform float freq;
    uniform float amp;
    uniform vec2 uSize;
    varying vec2 vUv;

    uniform sampler2D uTex;

    void main (void)
    {
        vec2  perturb;
        float rad;
        vec4  color;

        // Compute a perturbation factor for the x-direction
        rad = (vUv.s + vUv.t - 1.0 + StartRad) * freq;

        // Wrap to -2.0*PI, 2*PI
        rad = rad * C_2PI_I;
        rad = fract(rad);
        rad = rad * C_2PI;

        // Center in -PI, PI
        if (rad >  C_PI) rad = rad - C_2PI;
        if (rad < -C_PI) rad = rad + C_2PI;

        // Center in -PI/2, PI/2
        if (rad >  C_PI_2) rad =  C_PI - rad;
        if (rad < -C_PI_2) rad = -C_PI - rad;

        perturb.x  = (rad - (rad * rad * rad / 6.0)) * amp;

        // Now compute a perturbation factor for the y-direction
        rad = (vUv.s - vUv.t + StartRad) * freq;

        // Wrap to -2*PI, 2*PI
        rad = rad * C_2PI_I;
        rad = fract(rad);
        rad = rad * C_2PI;

        // Center in -PI, PI
        if (rad >  C_PI) rad = rad - C_2PI;
        if (rad < -C_PI) rad = rad + C_2PI;

        // Center in -PI/2, PI/2
        if (rad >  C_PI_2) rad =  C_PI - rad;
        if (rad < -C_PI_2) rad = -C_PI - rad;

        perturb.y  = (rad - (rad * rad * rad / 6.0)) * amp;
        vec2 pos = vUv.st;
        pos.x = 1.0 - pos.x;
        color = texture2D(uTex, perturb + pos);

        gl_FragColor = vec4(color.rgb, color.a);
    }
  """

class WashoutPass extends ShaderPassBase
  fragmentShader: """
    uniform vec2 uSize;
    varying vec2 vUv;
    uniform float amount;
    uniform sampler2D uTex;

    void main (void)
    {
      vec4 color = texture2D(uTex, vUv);
      gl_FragColor = color * (1.0 + amount);
    }
  """

class @ShaderPassBase
  constructor: (initialValues) ->
    @enabled = true
    @uniforms = THREE.UniformsUtils.clone @findUniforms(@fragmentShader)
    for key, value of initialValues
      @uniforms[key].value = value

    @material = new THREE.ShaderMaterial {
      uniforms: @uniforms
      vertexShader: @vertexShader
      fragmentShader: @fragmentShader
    }

    @enabled = true
    @renderToScreen = false
    @needsSwap = true

    @camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
    @scene  = new THREE.Scene();

    @quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), null)
    @scene.add @quad

  render: (renderer, writeBuffer, readBuffer, delta) ->
    @update?()
    if !@enabled
      writeBuffer = readBuffer
      return
    @uniforms['uTex'].value = readBuffer
    @uniforms['uSize'].value.set(readBuffer.width, readBuffer.height)
    @quad.material = @material
    if @renderToScreen
      renderer.render @scene, @camera
    else
      renderer.render @scene, @camera, writeBuffer, false

  standardUniforms: {
    uTex: {type: 't', value: null}
    uSize: {type: 'v2', value: new THREE.Vector2( 256, 256 )}
  }
  
  vertexShader: """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
  """

  findUniforms: (shader) ->
    lines = shader.split("\n")
    uniforms = {}
    for line in lines
      if (line.indexOf("uniform") == 0)
        tokens = line.split(" ")
        name = tokens[2].substring(0, tokens[2].length - 1)
        uniforms[name] = @typeToUniform tokens[1]
    uniforms

  typeToUniform: (type) ->
    switch type
      when "float" then {type: "f", value: 0}
      when "vec2" then {type: "v2", value: new THREE.Vector2}
      when "vec3" then {type: "v3", value: new THREE.Vector3}
      when "vec4" then {type: "v4", value: new THREE.Vector4}
      when "bool" then {type: "i", value: 0}
      when "sampler2D" then {type: "t", value: null}


renderer = null

composition = renderModel = composer = gui = stats = null

_init = () ->
  noise.seed(Math.random())
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, clearAlpha: 0, transparent: true})
  renderer.setSize(window.innerWidth, window.innerHeight)

  document.body.appendChild(renderer.domElement);

  gui = new dat.gui.GUI

  initPostProcessing()
  initCompositions()

  stats = new Stats
  stats.domElement.style.position = 'absolute'
  stats.domElement.style.left = '0px'
  stats.domElement.style.top = '0px'

  document.body.appendChild stats.domElement

initCompositions = () ->
  compositionPicker = new CompositionPicker
  document.body.appendChild compositionPicker.domElement
  compositionPicker.addComposition new CircleGrower
  compositionPicker.addComposition new SphereSphereComposition

window.setComposition = (comp) ->
  composition = comp
  composition.setup(renderer)
  renderModel.scene = composition.scene
  renderModel.camera = composition.camera
  

initPostProcessing = () ->
  composer = new THREE.EffectComposer(renderer)
  renderModel = new THREE.RenderPass(new THREE.Scene, new THREE.PerspectiveCamera)
  renderModel.renderToScreen = true
  composer.addPass renderModel

  
  addEffect new MirrorPass
  addEffect new InvertPass
  addEffect p = new ShroomPass
  p.enabled = true
  p.renderToScreen = true

addEffect = (effect) ->
  effect.enabled = false
  composer.addPass effect
  f = gui.addFolder effect.name
  f.add(effect, "enabled")
  if effect.uniformValues
    for values in effect.uniformValues
      f.add(effect.uniforms[values.uniform], "value", values.start, values.end).name(values.name)

_update = (t) ->
  composition?.update()

_animate = () ->
  composer.render()
  stats.update()
  # renderer.render(scene, camera)

window.loopF = (fn) ->
  f = () ->
    fn()
    requestAnimationFrame(f)
  f()

$ ->
  _init()
  loopF _update
  loopF _animate
class Gamepad
  @FACE_1: 0
  @FACE_2: 1
  @FACE_3: 2
  @FACE_4: 3
  @LEFT_SHOULDER: 4
  @RIGHT_SHOULDER: 5
  @LEFT_SHOULDER_BOTTOM: 6
  @RIGHT_SHOULDER_BOTTOM: 7
  @SELECT: 8
  @START: 9
  @LEFT_ANALOGUE_STICK: 10
  @RIGHT_ANALOGUE_STICK: 11
  @PAD_TOP: 12
  @PAD_BOTTOM: 13
  @PAD_LEFT: 14
  @PAD_RIGHT: 15
  @STICK_1: 16
  @STICK_2: 17

  @BUTTONS = [@FACE_1, @FACE_2, @FACE_3, @FACE_4, @LEFT_SHOULDER, @RIGHT_SHOULDER, @LEFT_SHOULDER_BOTTOM, @RIGHT_SHOULDER_BOTTOM, @SELECT, @START, @LEFT_ANALOGUE_STICK, @RIGHT_ANALOGUE_STICK, @PAD_TOP, @PAD_BOTTOM, @PAD_LEFT, @PAD_RIGHT]

  constructor: () ->
    @pad = null
    @callbacks = {}
    @callbacks[Gamepad.STICK_1] = []
    @callbacks[Gamepad.STICK_2] = []
    @buttonStates = {}
    for button in Gamepad.BUTTONS
      @buttonStates[button] = 0
    requestAnimationFrame @checkForPad

  checkForPad: () =>
    if navigator.webkitGetGamepads && navigator.webkitGetGamepads()[0]
      @pad = navigator.webkitGetGamepads()[0]
      requestAnimationFrame @checkButtons
    else
      requestAnimationFrame @checkForPad

  checkButtons: () =>
    @pad = navigator.webkitGetGamepads()[0]
    requestAnimationFrame @checkButtons
    for button in Gamepad.BUTTONS
      if @callbacks[button] && @buttonStates[button] != @pad.buttons[button]
        @buttonStates[button] = @pad.buttons[button]
        for buttonId, callback of @callbacks[button]
          callback(@pad.buttons[button])
    for callback in @callbacks[Gamepad.STICK_1]
      callback({x:@pad.axes[0],y:@pad.axes[1]})
    for callback in @callbacks[Gamepad.STICK_2]
      callback({x:@pad.axes[2],y:@pad.axes[3]})


  addEventListener: (button, callback) ->
    if !@callbacks[button] then @callbacks[button] = []
    @callbacks[button].push callback

class RGBShiftPass
  constructor: (r,g,b) ->
    shader = new RGBShiftShader
    @uniforms = THREE.UniformsUtils.clone shader.uniforms
    @uniforms['uRedShift'].value = r
    @uniforms['uGreenShift'].value = g
    @uniforms['uBlueShift'].value = b

    @material = new THREE.ShaderMaterial {
      uniforms: @uniforms
      vertexShader: shader.vertexShader
      fragmentShader: shader.fragmentShader
    }

    @enabled = true
    @renderToScreen = false
    @needsSwap = true

    @camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
    @scene  = new THREE.Scene();

    @quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), null)
    @scene.add @quad

  render: (renderer, writeBuffer, readBuffer, delta) ->
    @uniforms['uTex'].value = readBuffer
    @uniforms['uSize'].value.set(readBuffer.width, readBuffer.height)
    @quad.material = @material
    if @renderToScreen
      renderer.render @scene, @camera
    else
      renderer.render @scene, @camera, writeBuffer, false

class RGBShiftShader
  uniforms: {
    uTex: {type: 't', value: null}
    uSize: {type: 'v2', value: new THREE.Vector2( 256, 256 )}
    uRedShift: {type: 'f', value: 0.0}
    uGreenShift: {type: 'f', value: 0.0}
    uBlueShift: {type: 'f', value: 1.0}

  }
  
  vertexShader: """
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
  """

  fragmentShader: """
    uniform sampler2D uTex;
    uniform float uRedShift;
    uniform float uGreenShift;
    uniform float uBlueShift;
    uniform vec2 uSize;

    varying vec2 vUv;

    void main() {
      float r = texture2D(uTex, (vUv - 0.5) * vec2(uRedShift, 1.0) + 0.5).r;
      float g = texture2D(uTex, (vUv - 0.5) * vec2(uGreenShift, 1.0) + 0.5).g;
      float b = texture2D(uTex, (vUv - 0.5) * vec2(uBlueShift, 1.0) + 0.5).b;
      
      gl_FragColor = vec4(r,g,b,1.0);
    }
  """
class CompositionPicker
  constructor: () ->
    @compositions = []

    @domElement = document.createElement 'div'
    @domElement.className = 'composition-picker'
    @domElement.draggable = true
    for i in [0..1]
      slot = document.createElement 'div'
      slot.className = 'slot'
      @domElement.appendChild slot
    @domElement.addEventListener 'dragover', (e) =>
      e.preventDefault()
      e.target.classList.add 'dragover'
    @domElement.addEventListener 'dragleave', (e) =>
      e.preventDefault()
      e.target.classList.remove 'dragover'
    @domElement.addEventListener 'drop', (e) =>
      e.preventDefault()
      e.target.classList.remove 'dragover'
      @drop(e)

  addComposition: (comp) ->
    slot = new CompositionSlot(model: comp)
    @domElement.appendChild slot.render()

  drop: (e) ->
    file = e.dataTransfer.files[0]
    console.log file
    composition = new VideoComposition file
    @addComposition composition

class CompositionSlot extends Backbone.View
  className: 'slot'
  events:
    "click img": "launch"

  initialize: () =>
    super()
    @listenTo @model, "thumbnail-available", @render

  render: () =>
    @$el.html(@model.thumbnail)
    @el

  launch: () =>
    setComposition @model

