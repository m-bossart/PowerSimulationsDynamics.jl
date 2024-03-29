function initialize_outer!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{
            C,
            PSY.OuterControl{PSY.VirtualInertia, PSY.ReactivePowerDroop},
            IC,
            DC,
            P,
            F,
            L,
        },
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    P <: PSY.FrequencyEstimator,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}

    #Obtain external states inputs for component
    external_ix = get_input_port_ix(
        dynamic_device,
        PSY.OuterControl{PSY.VirtualInertia, PSY.ReactivePowerDroop},
    )
    Vr_filter = device_states[external_ix[1]]
    Vi_filter = device_states[external_ix[2]]
    Ir_filter = device_states[external_ix[3]]
    Ii_filter = device_states[external_ix[4]]

    Vr_cnv = inner_vars[Vr_cnv_var]
    Vi_cnv = inner_vars[Vi_cnv_var]
    θ0_oc = atan(Vi_cnv, Vr_cnv)

    ω_ref = device_parameters[ω_ref_ix]
    #Obtain additional expressions
    p_elec_out = Ir_filter * Vr_filter + Ii_filter * Vi_filter
    q_elec_out = -Ii_filter * Vr_filter + Ir_filter * Vi_filter

    #Update inner_vars
    inner_vars[P_ES_var] = p_elec_out
    #Update states
    outer_ix = get_local_state_ix(
        dynamic_device,
        PSY.OuterControl{PSY.VirtualInertia, PSY.ReactivePowerDroop},
    )
    outer_states = @view device_states[outer_ix]
    outer_states[1] = θ0_oc #θ_oc
    outer_states[2] = ω_ref
    outer_states[3] = q_elec_out #qm

    #Update inner vars
    inner_vars[θ_oc_var] = θ0_oc
    inner_vars[ω_oc_var] = ω_ref
    device_parameters[P_ref_ix] = p_elec_out
    PSY.set_P_ref!(
        PSY.get_active_power_control(PSY.get_outer_control(dynamic_device)),
        p_elec_out,
    )
    #Update Q_ref. Initialization assumes q_ref = q_elec_out of PF solution
    device_parameters[Q_ref_ix] = q_elec_out
    return
end

function initialize_outer!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{
            C,
            PSY.OuterControl{PSY.ActivePowerDroop, PSY.ReactivePowerDroop},
            IC,
            DC,
            P,
            F,
            L,
        },
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    P <: PSY.FrequencyEstimator,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}

    #Obtain external states inputs for component
    external_ix = get_input_port_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActivePowerDroop, PSY.ReactivePowerDroop},
    )
    Vr_filter = device_states[external_ix[1]]
    Vi_filter = device_states[external_ix[2]]
    Ir_filter = device_states[external_ix[3]]
    Ii_filter = device_states[external_ix[4]]

    Vr_cnv = inner_vars[Vr_cnv_var]
    Vi_cnv = inner_vars[Vi_cnv_var]
    θ0_oc = atan(Vi_cnv, Vr_cnv)

    #Obtain additional expressions
    p_elec_out = Ir_filter * Vr_filter + Ii_filter * Vi_filter
    q_elec_out = -Ii_filter * Vr_filter + Ir_filter * Vi_filter

    #Update inner_vars
    inner_vars[P_ES_var] = p_elec_out
    #Update states
    outer_ix = get_local_state_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActivePowerDroop, PSY.ReactivePowerDroop},
    )
    outer_states = @view device_states[outer_ix]
    outer_states[1] = θ0_oc #θ_oc
    outer_states[2] = p_elec_out #pm
    outer_states[3] = q_elec_out #qm

    #Update inner vars
    inner_vars[θ_oc_var] = θ0_oc
    inner_vars[ω_oc_var] = device_parameters[ω_ref_ix]
    #Update Q_ref. Initialization assumes q_ref = q_elec_out of PF solution
    device_parameters[P_ref_ix] = p_elec_out
    PSY.set_P_ref!(
        PSY.get_active_power_control(PSY.get_outer_control(dynamic_device)),
        p_elec_out,
    )
    device_parameters[Q_ref_ix] = q_elec_out
end

function initialize_outer!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{
            C,
            PSY.OuterControl{PSY.ActiveVirtualOscillator, PSY.ReactiveVirtualOscillator},
            IC,
            DC,
            P,
            F,
            L,
        },
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    P <: PSY.FrequencyEstimator,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}

    #Obtain external states inputs for component
    external_ix = get_input_port_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActiveVirtualOscillator, PSY.ReactiveVirtualOscillator},
    )
    Vr_filter = device_states[external_ix[1]]
    Vi_filter = device_states[external_ix[2]]
    Ir_filter = device_states[external_ix[3]]
    Ii_filter = device_states[external_ix[4]]

    Vr_cnv = inner_vars[Vr_cnv_var]
    Vi_cnv = inner_vars[Vi_cnv_var]
    θ0_oc = atan(Vi_cnv, Vr_cnv)

    #Obtain additional expressions
    p_elec_out = Ir_filter * Vr_filter + Ii_filter * Vi_filter
    q_elec_out = -Ii_filter * Vr_filter + Ir_filter * Vi_filter

    #Update inner_vars
    inner_vars[P_ES_var] = p_elec_out
    #Update states
    outer_ix = get_local_state_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActiveVirtualOscillator, PSY.ReactiveVirtualOscillator},
    )
    outer_states = @view device_states[outer_ix]
    outer_states[1] = θ0_oc #θ_oc
    outer_states[2] = 1.0 # V_ref will be computed in the inner control

    #Update inner vars
    inner_vars[θ_oc_var] = θ0_oc
    inner_vars[ω_oc_var] = device_parameters[ω_ref_ix]
    #Update Q_ref. Initialization assumes q_ref = q_elec_out of PF solution
    device_parameters[P_ref_ix] = p_elec_out
    PSY.set_P_ref!(
        PSY.get_active_power_control(PSY.get_outer_control(dynamic_device)),
        p_elec_out,
    )
    device_parameters[Q_ref_ix] = q_elec_out
end

function initialize_outer!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{
            C,
            PSY.OuterControl{PSY.ActivePowerPI, PSY.ReactivePowerPI},
            IC,
            DC,
            P,
            F,
            L,
        },
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    P <: PSY.FrequencyEstimator,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}

    #Obtain external states inputs for component
    external_ix = get_input_port_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActivePowerPI, PSY.ReactivePowerPI},
    )
    Vr_filter = device_states[external_ix[1]]
    Vi_filter = device_states[external_ix[2]]
    Ir_filter = device_states[external_ix[3]]
    Ii_filter = device_states[external_ix[4]]
    Ir_cnv = device_states[external_ix[5]]
    Ii_cnv = device_states[external_ix[6]]

    #Obtain additional expressions
    θ0_oc = inner_vars[θ_freq_estimator_var]
    I_dq_cnv = ri_dq(θ0_oc + pi / 2) * [Ir_cnv; Ii_cnv]
    p_elec_out = Ir_filter * Vr_filter + Ii_filter * Vi_filter
    q_elec_out = -Ii_filter * Vr_filter + Ir_filter * Vi_filter

    #Get Outer Controller parameters
    outer_control = PSY.get_outer_control(dynamic_device)
    active_power_control = PSY.get_active_power_control(outer_control)
    Ki_p = PSY.get_Ki_p(active_power_control) #Integral Gain
    reactive_power_control = PSY.get_reactive_power_control(outer_control)
    Ki_q = PSY.get_Ki_q(reactive_power_control) #Integral Gain

    #Update inner_vars
    inner_vars[P_ES_var] = p_elec_out
    #Update states
    outer_ix = get_local_state_ix(
        dynamic_device,
        PSY.OuterControl{PSY.ActivePowerPI, PSY.ReactivePowerPI},
    )
    outer_states = @view device_states[outer_ix]
    outer_states[1] = I_dq_cnv[q] / Ki_p #σp_oc
    outer_states[2] = p_elec_out #p_oc
    outer_states[3] = I_dq_cnv[d] / Ki_q #σq_oc
    outer_states[4] = q_elec_out #q_oc

    #Update inner vars
    inner_vars[θ_oc_var] = θ0_oc
    inner_vars[ω_oc_var] = device_parameters[ω_ref_ix]
    inner_vars[Id_oc_var] = I_dq_cnv[d]
    inner_vars[Iq_oc_var] = I_dq_cnv[q]
    #Update Q_ref. Initialization assumes q_ref = q_elec_out from PF solution
    device_parameters[P_ref_ix] = p_elec_out
    PSY.set_P_ref!(
        PSY.get_active_power_control(PSY.get_outer_control(dynamic_device)),
        p_elec_out,
    )
    device_parameters[Q_ref_ix] = q_elec_out
    PSY.set_Q_ref!(
        PSY.get_reactive_power_control(PSY.get_outer_control(dynamic_device)),
        q_elec_out,
    )
    return
end

function initialize_outer!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{
            C,
            PSY.OuterControl{
                PSY.ActiveRenewableControllerAB,
                PSY.ReactiveRenewableControllerAB,
            },
            IC,
            DC,
            P,
            F,
            L,
        },
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    P <: PSY.FrequencyEstimator,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}
    # Read inner vars
    Vr_filter = inner_vars[Vr_filter_var]
    Vi_filter = inner_vars[Vi_filter_var]
    Ir_filter = inner_vars[Ir_filter_var]
    Ii_filter = inner_vars[Ii_filter_var]
    V_t = sqrt(Vr_filter^2 + Vi_filter^2)

    Ir_cnv = inner_vars[Ir_cnv_var]
    Ii_cnv = inner_vars[Ii_cnv_var]
    Ir_cap = Ir_filter - Ir_cnv
    Ii_cap = Ii_filter - Ii_cnv
    Q_cap = -Ii_cap * Vr_filter + Ir_cap * Vi_filter

    p_elec_out = Ir_filter * Vr_filter + Ii_filter * Vi_filter
    q_elec_out = -Ii_filter * Vr_filter + Ir_filter * Vi_filter - Q_cap

    ## Set references
    Vm = V_t
    PSY.set_Q_ref!(PSY.get_converter(dynamic_device), q_elec_out)
    device_parameters[Q_ref_ix] = q_elec_out
    PSY.set_Q_ref!(
        PSY.get_reactive_power_control(PSY.get_outer_control(dynamic_device)),
        q_elec_out,
    )
    PSY.set_P_ref!(
        PSY.get_active_power_control(PSY.get_outer_control(dynamic_device)),
        p_elec_out,
    )
    device_parameters[P_ref_ix] = p_elec_out
    PSY.set_V_ref!(
        PSY.get_reactive_power_control(PSY.get_outer_control(dynamic_device)),
        Vm,
    )
    device_parameters[V_ref_ix] = Vm

    #Get Outer Controller parameters
    q_ref = device_parameters[Q_ref_ix]
    outer_control = PSY.get_outer_control(dynamic_device)
    active_power_control = PSY.get_active_power_control(outer_control)
    reactive_power_control = PSY.get_reactive_power_control(outer_control)
    Freq_Flag = PSY.get_Freq_Flag(active_power_control) #Frequency Flag

    #Set state counter for variable number of states due to flags
    state_ct = 1

    #Update inner_vars
    inner_vars[P_ES_var] = p_elec_out

    #Obtain indices for component w/r to device
    local_ix = get_local_state_ix(
        dynamic_device,
        PSY.OuterControl{
            PSY.ActiveRenewableControllerAB,
            PSY.ReactiveRenewableControllerAB,
        },
    )
    internal_states = @view device_states[local_ix]

    #Get all parameters once 
    local_ix_params = get_local_parameter_ix(
        dynamic_device,
        PSY.OuterControl{
            PSY.ActiveRenewableControllerAB,
            PSY.ReactiveRenewableControllerAB,
        },
    )
    internal_params = @view device_parameters[local_ix_params]
    active_n_params = get_n_params(active_power_control)
    active_ix_range_params = 1:active_n_params
    active_params = @view internal_params[active_ix_range_params]
    reactive_n_params = get_n_params(reactive_power_control)
    reactive_ix_range_params = (active_n_params + 1):(active_n_params + reactive_n_params)
    reactive_params = @view internal_params[reactive_ix_range_params]
    K_pg,
    K_ig,
    T_p,
    fdbd1,
    fdbd2,
    fe_min,
    fe_max,
    P_min,
    P_max,
    T_g,
    D_dn,
    D_up,
    dP_min,
    dP_max,
    P_min_inner,
    P_max_inner,
    T_pord = active_params
    T_fltr,
    K_p,
    K_i,
    T_ft,
    T_fv,
    V_frz,     # V_frz not implemented yet
    R_c,
    X_c,
    K_c,
    e_min,
    e_max,
    dbd1,
    dbd2,
    Q_min,
    Q_max,
    T_p,
    Q_min_inner,
    Q_max_inner,
    V_min,
    V_max,
    K_qp,
    K_qi = reactive_params

    if Freq_Flag == 1
        #Update States
        internal_states[state_ct] = p_elec_out
        internal_states[state_ct + 1] = p_elec_out / K_ig
        internal_states[state_ct + 2] = p_elec_out #p_ext
        internal_states[state_ct + 3] = p_elec_out #p_ord
        state_ct += 4
        #Update Inner Vars
        inner_vars[Id_oc_var] = p_elec_out / max(V_t, 0.01)
    else
        #Update States
        internal_states[state_ct] = p_elec_out
        #Update Inner Vars
        inner_vars[Id_oc_var] = p_elec_out / max(V_t, 0.01)
        state_ct += 1
    end

    reactive_power_control = PSY.get_reactive_power_control(outer_control)
    # Note: Monitoring power from other branch not supported.
    VC_Flag = PSY.get_VC_Flag(reactive_power_control)
    Ref_Flag = PSY.get_Ref_Flag(reactive_power_control)
    PF_Flag = PSY.get_PF_Flag(reactive_power_control)
    V_Flag = PSY.get_V_Flag(reactive_power_control)
    # Update references
    if Ref_Flag == 0 && PF_Flag == 0 && V_Flag == 1
        #Update states
        internal_states[state_ct] = q_elec_out
        internal_states[state_ct + 1] = q_elec_out / K_i
        internal_states[state_ct + 2] = q_elec_out
        internal_states[state_ct + 3] = V_t / K_qi
        state_ct += 4
        #Update Inner Vars
        inner_vars[V_oc_var] = 0.0
        inner_vars[Iq_oc_var] = q_elec_out / max(V_t, 0.01)
    elseif Ref_Flag == 0 && PF_Flag == 0 && V_Flag == 0
        #Update states
        internal_states[state_ct] = q_ref
        internal_states[state_ct + 1] = q_ref / K_i
        internal_states[state_ct + 2] = q_ref
        state_ct += 3
        #Update Inner Vars
        inner_vars[V_oc_var] = q_ref - V_t
        inner_vars[Iq_oc_var] = q_ref / max(V_t, 0.01)
    elseif Ref_Flag == 1 && PF_Flag == 0 && V_Flag == 1
        K_i = PSY.get_K_i(reactive_power_control)
        K_qi = PSY.get_K_qi(reactive_power_control)
        K_c = PSY.get_K_c(reactive_power_control)
        R_c = PSY.get_R_c(reactive_power_control)
        X_c = PSY.get_R_c(reactive_power_control)
        VC_Flag = PSY.get_VC_Flag(reactive_power_control)
        V_reg = sqrt(Vr_filter^2 + Vi_filter^2)
        # Compute input to the compensated voltage filter
        if VC_Flag == 0
            V_flt_input = V_reg + K_c * q_elec_out
        else
            # Calculate compensated voltage: | V_reg - (R_c + jX_c)(I_r + jI_i) |
            V_flt_input = sqrt(
                V_reg^2 +
                2 * V_reg * (Ii_filter * X_c - Ir_filter * R_c) +
                (Ii_filter^2 + Ir_filter^2) * (R_c^2 + X_c^2),
            )
        end
        #Update states
        internal_states[state_ct] = V_flt_input #Vc_flt
        internal_states[state_ct + 1] = q_elec_out / K_i
        internal_states[state_ct + 2] = q_elec_out
        internal_states[state_ct + 3] = V_t / K_qi
        #Update Inner Vars
        inner_vars[V_oc_var] = 0.0
        inner_vars[Iq_oc_var] = q_elec_out / max(V_t, 0.01)
    elseif Ref_Flag == 1 && PF_Flag == 0 && V_Flag == 0
        # TODO: Fix and debug this case when Q_Flag = 1
        VC_Flag = PSY.get_VC_Flag(reactive_power_control)
        V_reg = sqrt(Vr_filter^2 + Vi_filter^2)
        # Compute input to the compensated voltage filter
        if VC_Flag == 0
            V_flt_input = V_reg + K_c * q_elec_out
        else
            # Calculate compensated voltage: | V_reg - (R_c + jX_c)(I_r + jI_i) |
            V_flt_input = sqrt(
                V_reg^2 +
                2 * V_reg * (Ii_filter * X_c - Ir_filter * R_c) +
                (Ii_filter^2 + Ir_filter^2) * (R_c^2 + X_c^2),
            )
        end
        #Update states
        internal_states[state_ct] = V_flt_input #Vc_flt
        internal_states[state_ct + 1] = q_elec_out / K_i
        internal_states[state_ct + 2] = q_elec_out
        #Update Inner Vars
        inner_vars[V_oc_var] = 0.0
        inner_vars[Iq_oc_var] = q_elec_out / max(V_t, 0.01)
    else
        error("Flags for Generic Renewable Model not supported yet")
    end
    return
end
