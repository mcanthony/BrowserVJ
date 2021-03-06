class RandomShapeComposition extends CanvasComposition
  name: "Random Shapes"

  constructor: () ->
    super()
    @shapes = []

  inputs: [
    {name: "trigger", type: "boolean"}
    {name: "Triangle", type: "boolean"}
    {name: "Square", type: "boolean"}
    {name: "Circle", type: "boolean"}
    {name: "Fill", type: "boolean", toggle: true}
    {name: "color", type: "color", default: "#FF0000"}
  ]

  "change:trigger": (obj, val) =>
    if val
      shape = ["Square", "Triangle", "Circle"][Math.floor(Math.random()*3)]
      @shapes.push({shape: shape, life: 1})

  "change:Triangle": (obj, val) =>
    if val
      @shapes.push({shape: "Triangle", life: 1})

  "change:Circle": (obj, val) =>
    if val
      @shapes.push({shape: "Circle", life: 1})

  "change:Square": (obj, val) =>
    if val
      @shapes.push({shape: "Square", life: 1})

  draw: () ->
    ctx = @canvas.getContext("2d")
    ctx.save()
    ctx.clearRect(0, 0, @canvas.width, @canvas.height)
    ctx.strokeStyle = ctx.fillStyle = @get("color").toString()
    ctx.lineWidth = 5
    ctx.translate(@canvas.width / 2, @canvas.height / 2)
    for shape in @shapes
      ctx.globalAlpha = shape.life
      size = 150 + 300 * (1 - shape.life)
      @["draw#{shape.shape}"](ctx, size)
      shape.life -= 0.03
    @shapes = @shapes.filter (s) -> s.life > 0
    ctx.globalAlpha = 1
    ctx.restore()

  drawSquare: (ctx, size) ->
    if @get("Fill")
      ctx.fillRect(-size / 2, -size / 2, size, size)
    else
      ctx.strokeRect(-size / 2, -size / 2, size, size)

  drawCircle: (ctx, size) ->
    ctx.beginPath()
    ctx.arc(0, 0, size / 2, size / 2, 0, 2 * Math.PI, false)
    if @get("Fill")
      ctx.fill()
    else
      ctx.stroke()

  drawTriangle: (ctx, size) ->
    ctx.beginPath()
    ctx.moveTo(0, -size / 2)
    p1x = size / 2 * Math.sin(2 * Math.PI / 3)
    p1y = -size / 2 * Math.cos(2 * Math.PI / 3)
    ctx.lineTo(p1x, p1y)
    p2x = size / 2 * Math.sin(4 * Math.PI / 3)
    p2y = -size / 2 * Math.cos(4 * Math.PI / 3)
    ctx.lineTo(p2x, p2y)
    ctx.closePath()
    if @get("Fill")
      ctx.fill()
    else
      ctx.stroke()
    