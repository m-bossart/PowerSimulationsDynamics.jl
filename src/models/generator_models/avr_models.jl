##################################
###### Mass Matrix Entries #######
##################################

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::T,
    global_index::Base.ImmutableDict{Symbol, Int64},
) where {T <: PSY.AVR}
    @debug "Using default mass matrix entries $T"
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.SEXS,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vf], global_index[:Vf]] = PSY.get_Te(avr)
    mass_matrix[global_index[:Vr], global_index[:Vr]] = PSY.get_Tb(avr)
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.SCRX,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vr1], global_index[:Vr1]] = PSY.get_Tb(avr) # left hand side
    mass_matrix[global_index[:Vr2], global_index[:Vr2]] = PSY.get_Te(avr) #
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.EXST1,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vm], global_index[:Vm]] = PSY.get_Tr(avr)
    mass_matrix[global_index[:Vrll], global_index[:Vrll]] = PSY.get_Tb(avr)
    mass_matrix[global_index[:Vr], global_index[:Vr]] = PSY.get_Ta(avr)
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.EXAC1,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vm], global_index[:Vm]] = PSY.get_Tr(avr)
    mass_matrix[global_index[:Vr1], global_index[:Vr1]] = PSY.get_Tb(avr)
    mass_matrix[global_index[:Vr2], global_index[:Vr2]] = PSY.get_Ta(avr)
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.ESST1A,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vm], global_index[:Vm]] = PSY.get_Tr(avr)
    mass_matrix[global_index[:Vr1], global_index[:Vr1]] = PSY.get_Tb(avr)
    mass_matrix[global_index[:Vr2], global_index[:Vr2]] = PSY.get_Tb1(avr)
    mass_matrix[global_index[:Va], global_index[:Va]] = PSY.get_Ta(avr)
    return
end

function mass_matrix_avr_entries!(
    mass_matrix,
    avr::PSY.ST6B,
    global_index::Base.ImmutableDict{Symbol, Int64},
)
    mass_matrix[global_index[:Vm], global_index[:Vm]] = PSY.get_Tr(avr)
    mass_matrix[global_index[:x_d], global_index[:x_d]] = PSY.get_T_da(avr)
    return
end

##################################
##### Differential Equations #####
##################################

function mdl_avr_ode!(
    ::AbstractArray{<:ACCEPTED_REAL_TYPES},
    ::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.AVRFixed, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}
    V_ref = p[:refs][:V_ref]
    #Update Vf voltage on inner vars. In AVRFixed, Vf = V_ref
    inner_vars[Vf_var] = V_ref
    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.AVRSimple, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.AVRSimple)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vf = internal_states[1]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2)

    #Get Parameters
    Kv = p[:params][:AVR][:Kv]

    #Compute ODEs
    output_ode[local_ix[1]] = Kv * (V_ref - V_th)

    #Update inner_vars
    inner_vars[Vf_var] = Vf

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.AVRTypeI, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}
    #Obtain references
    V0_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.AVRTypeI)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vf = internal_states[1]
    Vr1 = internal_states[2]
    Vr2 = internal_states[3]
    Vm = internal_states[4]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2)
    Vs = inner_vars[V_pss_var]

    #Get parameters
    params = p[:params][:AVR]
    Ka = params[:Ka]
    Ke = params[:Ke]
    Kf = params[:Kf]
    Ta = params[:Ta]
    Te = params[:Te]
    Tf = params[:Tf]
    Tr = params[:Tr]
    Ae = params[:Ae]
    Be = params[:Be]

    #Compute auxiliary parameters
    Se_Vf = Ae * exp(Be * abs(Vf)) #16.13
    V_ref = V0_ref + Vs

    # Compute block derivatives
    _, dVm_dt = low_pass(V_th, Vm, 1.0, Tr)
    y_hp, dVr2_dt = high_pass(Vf, Vr2, Kf, Tf)
    _, dVr1_dt = low_pass(V_ref - Vm - y_hp, Vr1, Ka, Ta)
    _, dVf_dt = low_pass_modified(Vr1, Vf, 1.0, Ke + Se_Vf, Te)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVf_dt #16.12c
    output_ode[local_ix[2]] = dVr1_dt #16.12a
    output_ode[local_ix[3]] = dVr2_dt #16.12b
    output_ode[local_ix[4]] = dVm_dt #16.11

    #Update inner_vars
    inner_vars[Vf_var] = Vf

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars,
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.AVRTypeII, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V0_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.AVRTypeII)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vf = internal_states[1]
    Vr1 = internal_states[2]
    Vr2 = internal_states[3]
    Vm = internal_states[4]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2)
    Vs = inner_vars[V_pss_var]

    #Get parameters
    params = p[:params][:AVR]
    K0 = params[:K0]
    T1 = params[:T1]
    T2 = params[:T2]
    T3 = params[:T3]
    T4 = params[:T4]
    Te = params[:Te]
    Tr = params[:Tr]
    Va_min = params[:Va_lim][:min]
    Va_max = params[:Va_lim][:max]
    Ae = params[:Ae]
    Be = params[:Be]

    #Compute auxiliary parameters
    Se_Vf = Ae * exp(Be * abs(Vf)) #16.13
    V_ref = V0_ref + Vs

    # Compute block derivatives
    _, dVm_dt = low_pass(V_th, Vm, 1.0, Tr)
    y_ll1, dVr1_dt = lead_lag(V_ref - Vm, Vr1, K0, T2, T1)
    y_ll2, dVr2_dt = lead_lag(y_ll1, K0 * Vr2, 1.0, K0 * T4, K0 * T3)
    Vr = clamp(y_ll2, Va_min, Va_max)
    _, dVf_dt = low_pass_modified(Vr, Vf, 1.0, 1.0 + Se_Vf, Te)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVf_dt #16.18
    output_ode[local_ix[2]] = dVr1_dt #16.14
    output_ode[local_ix[3]] = dVr2_dt
    output_ode[local_ix[4]] = dVm_dt #16.11

    #Update inner_vars
    inner_vars[Vf_var] = Vf

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.ESAC1A, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V_ref = p[:refs][:V_ref]

    #Obtain avr
    avr = PSY.get_avr(dynamic_device)

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, typeof(avr))

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vm = internal_states[1]
    Vr1 = internal_states[2]
    Vr2 = internal_states[3]
    Ve = internal_states[4]
    Vr3 = internal_states[5]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2)
    Vs = inner_vars[V_pss_var]
    Xad_Ifd = inner_vars[Xad_Ifd_var]

    #Get parameters
    params = p[:params][:AVR]
    Tr = params[:Tr]
    Tb = params[:Tb]
    Tc = params[:Tc]
    Ka = params[:Ka]
    Ta = params[:Ta]
    Va_min = params[:Va_lim][:min]
    Va_max = params[:Va_lim][:max]
    Te = params[:Te]
    Kf = params[:Kf]
    Tf = params[:Tf]
    Kc = params[:Kc]
    Kd = params[:Kd]
    Ke = params[:Ke]
    Vr_min = params[:Vr_lim][:min]
    Vr_max = params[:Vr_lim][:max]
    inv_Tr = Tr < eps() ? 1.0 : 1.0 / Tr
    #Obtain saturation
    Se = saturation_function(avr, Ve)

    #Compute auxiliary parameters
    I_N = Kc * Xad_Ifd / Ve
    V_FE = Kd * Xad_Ifd + Ke * Ve + Se * Ve
    Vf = Ve * rectifier_function(I_N)

    # Compute blocks
    _, dVm_dt = low_pass(V_th, Vm, 1.0, 1.0 / inv_Tr)
    V_F, dVr3_dt = high_pass(V_FE, Vr3, Kf, Tf)
    V_in = V_ref + Vs - Vm - V_F
    y_ll, dVr1_dt = lead_lag(V_in, Vr1, 1.0, Tc, Tb)
    _, dVr2_dt = low_pass_nonwindup(y_ll, Vr2, Ka, Ta, Va_min, Va_max)

    #Set clamping for Vr2.
    V_R = clamp(Vr2, Vr_min, Vr_max)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVm_dt
    output_ode[local_ix[2]] = dVr1_dt #dVr1/dt
    output_ode[local_ix[3]] = dVr2_dt
    output_ode[local_ix[4]] = (1.0 / Te) * (V_R - V_FE) #dVe/dt
    output_ode[local_ix[5]] = dVr3_dt

    #Update inner_vars
    inner_vars[Vf_var] = Vf

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.SEXS, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}
    #Obtain references
    V0_ref = p[:refs][:V_ref]
    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.SEXS)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vf = internal_states[1]
    Vr = internal_states[2]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2)
    Vs = inner_vars[V_pss_var]

    #Get parameters
    params = @view(p[:params][:AVR])
    Ta_Tb = params[:Ta_Tb]
    Tb = params[:Tb]
    K = params[:K]
    Te = params[:Te]
    V_min = params[:V_lim][:min]
    V_max = params[:V_lim][:max]
    Ta = Tb * Ta_Tb

    #Compute auxiliary parameters
    V_in = V0_ref + Vs - V_th
    V_LL, dVr_dt = lead_lag_mass_matrix(V_in, Vr, 1.0, Ta, Tb)
    _, dVf_dt = low_pass_nonwindup_mass_matrix(V_LL, Vf, K, Te, V_min, V_max)

    #Compute 2 States AVR ODE:
    output_ode[local_ix[1]] = dVf_dt
    output_ode[local_ix[2]] = dVr_dt

    #Update inner_vars
    inner_vars[Vf_var] = Vf

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray{<:ACCEPTED_REAL_TYPES},
    output_ode::AbstractArray{<:ACCEPTED_REAL_TYPES},
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray{<:ACCEPTED_REAL_TYPES},
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.SCRX, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V0_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.SCRX) #

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vr1 = internal_states[1]
    Vr2 = internal_states[2]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2) # real and imaginary >> Ec
    Vs = inner_vars[V_pss_var] #Vs, PSS output
    Ifd = inner_vars[Xad_Ifd_var] # read Lad Ifd

    #Get parameters << keep
    avr = PSY.get_avr(dynamic_device)
    params = p[:params][:AVR]
    Ta_Tb = params[:Ta_Tb]
    Tb = params[:Tb]
    Ta = Tb * Ta_Tb
    Te = params[:Te]
    K = params[:K]
    V_min, V_max = params[:Efd_lim]
    switch = PSY.get_switch(avr)
    rc_rfd = params[:rc_rfd]

    #Compute auxiliary parameters << keep
    V_in = V0_ref + Vs - V_th #sum of V
    V_LL, dVr1_dt = lead_lag_mass_matrix(V_in, Vr1, 1.0, Ta, Tb) # 1st block
    Vr2_sat, dVr2_dt = low_pass_nonwindup_mass_matrix(V_LL, Vr2, K, Te, V_min, V_max) # gain K , 2nd block

    # Switch multiplier
    mult = switch == 0 ? V_th : one(typeof(V_th))
    V_ex = mult * Vr2_sat

    #Negative current logic
    if rc_rfd == 0.0 # a float
        E_fd = V_ex
    else
        E_fd = Ifd > 0.0 ? V_ex : -Ifd * rc_rfd
    end

    #Compute 2 States AVR ODE: << move this after? (final computation)
    output_ode[local_ix[1]] = dVr1_dt
    output_ode[local_ix[2]] = dVr2_dt

    #Update inner_vars << do this after
    inner_vars[Vf_var] = E_fd # field voltage from rc_rfd

    return
end

function mdl_avr_ode!(
    device_states::AbstractArray,
    output_ode::AbstractArray,
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray,
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.EXST1, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V0_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.EXST1)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vm = internal_states[1]
    Vrll = internal_states[2]
    Vr = internal_states[3]
    Vfb = internal_states[4]

    #Define external states for device
    Vt = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2) # machine's terminal voltage
    Vs = inner_vars[V_pss_var] # PSS output 
    Ifd = inner_vars[Xad_Ifd_var] # machine's field current in exciter base 

    #Get Parameters
    params = p[:params][:AVR]
    Tr = params[:Tr]
    Vi_min = params[:Vi_lim][:min]
    Vi_max = params[:Vi_lim][:max]
    Tc = params[:Tc]
    Tb = params[:Tb]
    Ka = params[:Ka]
    Ta = params[:Ta]
    Vr_min = params[:Vr_lim][:min]
    Vr_max = params[:Vr_lim][:max]
    Kc = params[:Kc]
    Kf = params[:Kf]
    Tf = params[:Tf]

    #Compute auxiliary parameters
    V_ref = V0_ref + Vs

    # Compute block derivatives
    _, dVm_dt = low_pass_mass_matrix(Vt, Vm, 1.0, Tr)
    y_hp, dVfb_dt = high_pass(Vr, Vfb, Kf, Tf)
    y_ll, dVrll_dt =
        lead_lag_mass_matrix(clamp(V_ref - Vm - y_hp, Vi_min, Vi_max), Vrll, 1.0, Tc, Tb)
    _, dVr_dt = low_pass_mass_matrix(y_ll, Vr, Ka, Ta)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVm_dt
    output_ode[local_ix[2]] = dVrll_dt
    output_ode[local_ix[3]] = dVr_dt
    output_ode[local_ix[4]] = dVfb_dt

    #Update inner_vars
    Vf = clamp(Vr, Vt * Vr_min - Kc * Ifd, Vt * Vr_max - Kc * Ifd)
    inner_vars[Vf_var] = Vf
    return
end

function mdl_avr_ode!(
    device_states::AbstractArray,
    output_ode::AbstractArray,
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray,
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.EXAC1, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V_ref = p[:refs][:V_ref]

    #Obtain avr
    avr = PSY.get_avr(dynamic_device)

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, typeof(avr))

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vm = internal_states[1]
    Vr1 = internal_states[2]
    Vr2 = internal_states[3]
    Ve = internal_states[4]
    Vr3 = internal_states[5]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2) # machine's terminal voltage
    Vs = inner_vars[V_pss_var] # PSS output 
    Xad_Ifd = inner_vars[Xad_Ifd_var] # machine's field current in exciter base

    #Get parameters
    params = p[:params][:AVR]
    Tr = params[:Tr]
    Tb = params[:Tb]
    Tc = params[:Tc]
    Ka = params[:Ka]
    Ta = params[:Ta]
    Vr_min = params[:Vr_lim][:min]
    Vr_max = params[:Vr_lim][:max]
    Te = params[:Te]
    Kf = params[:Kf]
    Tf = params[:Tf]
    Kc = params[:Kc]
    Kd = params[:Kd]
    Ke = params[:Ke]

    #Obtain saturation
    Se = saturation_function(avr, Ve)

    #Compute auxiliary parameters
    I_N = Kc * Xad_Ifd / Ve
    V_FE = Kd * Xad_Ifd + Ke * Ve + Se * Ve
    Vf = Ve * rectifier_function(I_N)

    #Compute block derivatives
    _, dVm_dt = low_pass_mass_matrix(V_th, Vm, 1.0, Tr)
    V_F, dVr3_dt = high_pass(V_FE, Vr3, Kf, Tf)
    V_in = V_ref + Vs - Vm - V_F
    y_ll, dVr1_dt = lead_lag_mass_matrix(V_in, Vr1, 1.0, Tc, Tb)
    y_Vr, dVr2_dt = low_pass_nonwindup_mass_matrix(y_ll, Vr2, Ka, Ta, Vr_min, Vr_max)
    _, dVe_dt = integrator_nonwindup(y_Vr - V_FE, Ve, 1.0, Te, 0.0, Inf)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVm_dt
    output_ode[local_ix[2]] = dVr1_dt
    output_ode[local_ix[3]] = dVr2_dt
    output_ode[local_ix[4]] = dVe_dt
    output_ode[local_ix[5]] = dVr3_dt

    #Update inner_vars
    inner_vars[Vf_var] = Vf
    return
end

function mdl_avr_ode!(
    device_states::AbstractArray,
    output_ode::AbstractArray,
    p::AbstractArray{<:ACCEPTED_REAL_TYPES},
    inner_vars::AbstractArray,
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.ESST1A, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V0_ref = p[:refs][:V_ref]

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, PSY.ESST1A)

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vm = internal_states[1]
    Vr1 = internal_states[2]
    Vr2 = internal_states[3]
    Va = internal_states[4]
    Vr3 = internal_states[5]

    #Define external states for device
    Vt = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2) # machine's terminal voltage
    Vs = inner_vars[V_pss_var] # PSS output 
    Ifd = inner_vars[Xad_Ifd_var] # machine's field current in exciter base 

    #Get parameters
    avr = PSY.get_avr(dynamic_device)
    params = p[:params][:AVR]
    UEL = PSY.get_UEL_flags(avr)
    VOS = PSY.get_PSS_flags(avr)
    Tr = params[:Tr]
    Vi_min = params[:Vi_lim][:min]
    Vi_max = params[:Vi_lim][:max]
    Tc = params[:Tc]
    Tb = params[:Tb]
    Tc1 = params[:Tc1]
    Tb1 = params[:Tb1]
    Ka = params[:Ka]
    Ta = params[:Ta]
    Va_min = params[:Va_lim][:min]
    Va_max = params[:Va_lim][:max]
    Vr_min = params[:Vr_lim][:min]
    Vr_max = params[:Vr_lim][:max]
    Kc = params[:Kc]
    Kf = params[:Kf]
    Tf = params[:Tf]
    K_lr = params[:K_lr]
    I_lr = params[:I_lr]

    #Compute auxiliary parameters
    Itemp = K_lr * (Ifd - I_lr)
    Iresult = Itemp > 0.0 ? Itemp : 0.0

    if VOS == 1
        V_ref = V0_ref + Vs
        Va_sum = Va - Iresult
    elseif VOS == 2
        V_ref = V0_ref
        Va_sum = Va - Iresult + Vs
    end

    # Compute block derivatives
    _, dVm_dt = low_pass_mass_matrix(Vt, Vm, 1.0, Tr)
    y_hp, dVr3_dt = high_pass(Va_sum, Vr3, Kf, Tf)
    y_ll1, dVr1_dt =
        lead_lag_mass_matrix(clamp(V_ref - Vm - y_hp, Vi_min, Vi_max), Vr1, 1.0, Tc, Tb)
    y_ll2, dVr2_dt =
        lead_lag_mass_matrix(y_ll1, Vr2, 1.0, Tc1, Tb1)
    _, dVa_dt = low_pass_nonwindup_mass_matrix(y_ll2, Va, Ka, Ta, Va_min, Va_max)

    #Compute 5 States AVR ODE:
    output_ode[local_ix[1]] = dVm_dt
    output_ode[local_ix[2]] = dVr1_dt
    output_ode[local_ix[3]] = dVr2_dt
    output_ode[local_ix[4]] = dVa_dt
    output_ode[local_ix[5]] = dVr3_dt

    #Update inner_vars
    Vf = clamp(Va_sum, Vt * Vr_min, Vt * Vr_max - Kc * Ifd)
    inner_vars[Vf_var] = Vf
    return
end

######################################################################
function mdl_avr_ode!(
    device_states::AbstractArray,
    output_ode::AbstractArray,
    inner_vars::AbstractArray,
    dynamic_device::DynamicWrapper{PSY.DynamicGenerator{M, S, PSY.ST6B, TG, P}},
    h,
    t,
) where {M <: PSY.Machine, S <: PSY.Shaft, TG <: PSY.TurbineGov, P <: PSY.PSS}

    #Obtain references
    V_ref = get_V_ref(dynamic_device)

    #Obtain avr
    avr = PSY.get_avr(dynamic_device)

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(dynamic_device, typeof(avr))

    #Define inner states for component
    internal_states = @view device_states[local_ix]
    Vm = internal_states[1]
    x_i = internal_states[2]
    x_d = internal_states[3]
    Vg = internal_states[4]

    #Define external states for device
    V_th = sqrt(inner_vars[VR_gen_var]^2 + inner_vars[VI_gen_var]^2) # machine's terminal voltage
    Vs = inner_vars[V_pss_var] # PSS output 
    Xad_Ifd = inner_vars[Xad_Ifd_var] # machine's field current in exciter base

    #Get parameters
    Tr = PSY.get_Tr(avr)
    K_pa = PSY.get_K_pa(avr) #k_pa>0
    K_ia = PSY.get_K_ia(avr)
    K_da = PSY.get_K_da(avr)
    T_da = PSY.get_T_da(avr)
    Va_min, Va_max = PSY.get_Va_lim(avr)
    K_ff = PSY.get_K_ff(avr)
    K_m = PSY.get_K_m(avr)
    K_ci = PSY.get_K_ci(avr) #K_cl in pss
    K_lr = PSY.get_K_lr(avr)
    I_lr = PSY.get_I_lr(avr)
    Vr_min, Vr_max = PSY.get_Vr_lim(avr)
    Kg = PSY.get_Kg(avr)
    Tg = PSY.get_Tg(avr) #T_g>0

    #Compute block derivatives
    _, dVm_dt = low_pass_mass_matrix(V_th, Vm, 1.0, Tr)
    pid_input = V_ref + Vs - Vm
    pi_out, dx_i = pi_block_nonwindup(pid_input, x_i, K_pa, K_ia, Va_min, Va_max)
    pd_out, dx_d = high_pass_mass_matrix(pid_input, x_d, K_da, T_da)
    Va = pi_out + pd_out

    ff_out = ((Va - Vg) * K_m) + (K_ff * Va)
    V_r1 = max(((I_lr * K_ci) - Xad_Ifd) * K_lr, Vr_min)
    V_r2 = clamp(ff_out, Vr_min, Vr_max)
    V_r = min(V_r1, V_r2)
    E_fd = V_r * Vm
    _, dVg = low_pass(E_fd, Vg, Kg, Tg)

    #Compute 4 States AVR ODE:
    output_ode[local_ix[1]] = dVm_dt
    output_ode[local_ix[2]] = dx_i
    output_ode[local_ix[3]] = dx_d
    output_ode[local_ix[4]] = dVg

    #Update inner_vars
    inner_vars[Vf_var] = E_fd
    return
end
