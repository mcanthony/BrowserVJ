SPEED = 1 / 20000

class BlobbyComposition extends Composition
  name: "Blobby"

  inputs: [
    {name: "Level", type: "number", min: 0, max: 1, default: 0}
  ]
  setup: (@renderer) ->
    @time = 0
    @scene = new THREE.Scene
    @scene.fog = new THREE.FogExp2( 0x000000, 0.0005 );
    @camera = new THREE.PerspectiveCamera(75, @renderer.domElement.width / @renderer.domElement.height, 1, 10000);
    @camera.position.z = 1000;

    sprite = new THREE.ImageUtils.loadTexture("assets/disc.png")
    sprite.premultiplyAlpha = true
    sprite.needsUpdate = true
    geometry = new THREE.Geometry
    for i in [0..1000]
      vtx = new THREE.Vector3
      vtx.x = 500 * Math.random() - 250
      vtx.y = 500 * Math.random() - 250
      vtx.z = 500 * Math.random() - 250
      vtx.seed = i
      geometry.vertices.push vtx
    material = new THREE.ParticleSystemMaterial({size: 135, map: sprite, transparent: true})
    material.color.setHSL( 1.0, 0.3, 0.7 );
    material.opacity = 0.2
    material.blending = THREE.AdditiveBlending
    @particles = new THREE.ParticleSystem geometry, material
    @particles.sortParticles = true
    @scene.add @particles

  update: () ->
    @time += .004
    @particles.rotation.y += 0.01

    a = @get("Level") * 500
    a = a + 1
    a = Math.max a, 60
    for vertex in @particles.geometry.vertices
      vertex.x = noise.simplex2(@time, vertex.seed) * a
      vertex.y = noise.simplex2(vertex.seed, @time) * a
      vertex.z = noise.simplex2(@time + vertex.seed, vertex.seed) * a

