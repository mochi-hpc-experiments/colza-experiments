#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
#            SIMULATION STOP            #
#.......................................#
time.stop_time               =   10     # Max (simulated) time to evolve
time.max_step                =  200     # Max number of time steps
time.init_shrink = 0.001

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
# TIME STEP COMPUTATION #
#.......................................#
time.fixed_dt         =   -0.001        # Use this constant dt if > 0
time.cfl              =   0.8           # CFL factor
time.initial_dt = 0.001

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
# INPUT AND OUTPUT #
#.......................................#
io.KE_int = 0
io.line_plot_int = 5
#io.restart_file = chk00300
time.plot_interval            =  5       # Steps between plot files
time.checkpoint_interval      =  300     # Steps between checkpoint files
time.checkpoint_start         =  300

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
# PHYSICS #
#.......................................#
incflo.use_godunov = 1
incflo.godunov_type="weno"
transport.model = TwoPhaseTransport
transport.laminar_prandtl = 0.7
transport.turbulent_prandtl = 0.3333
turbulence.model = Laminar

incflo.physics = MultiPhase DamBreak
MultiPhase.density_fluid1=1000.
MultiPhase.density_fluid2=1.0
MultiPhase.verbose = 1
DamBreak.height=0.0571
DamBreak.width=0.0571
ICNS.source_terms = GravityForcing

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
# ADAPTIVE MESH REFINEMENT #
#.......................................#
amr.n_cell              = 80 16 24      # Grid cells at coarsest AMRlevel
amr.max_level           = 1             # Max AMR level in hierarchy
amr.max_grid_size      = 64
amr.blocking_factor     = 8
time.regrid_interval =  5
tagging.labels = TO1
tagging.TO1.type = InterfaceThicknessRefinement
tagging.labels = grad
tagging.grad.type = GradientMagRefinement
tagging.grad.field_name = density
tagging.grad.values = 10 10 10 10 10

#¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨#
# GEOMETRY #
#.......................................#
geometry.prob_lo = 0 0. 0. # Lo corner coordinates
geometry.prob_hi = 0.2855 0.0571 0.08565 # Hi corner coordinates
geometry.is_periodic = 0 1 0 # Periodicity x y z (0/1)

xlo.type = "slip_wall"
xhi.type = "slip_wall"
zlo.type = "slip_wall"
zhi.type = "slip_wall"

#incflo.post_processing = ascent
#ascent.type = Ascent
#ascent.fields = velocity
#ascent.output_frequency = 5

incflo.post_processing = colza
colza.type = Colza
colza.fields = velocity
colza.protocol = "ofi+tcp"
colza.provider_id = 0
colza.ssg_file = "colza.ssg"
colza.pipeline_name = "colza_ascent_pipeline"
