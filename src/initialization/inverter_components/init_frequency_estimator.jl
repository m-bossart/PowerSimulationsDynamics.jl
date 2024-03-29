function initialize_frequency_estimator!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{PSY.DynamicInverter{C, O, IC, DC, PSY.KauraPLL, F, L}},
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    O <: PSY.OuterControl,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}
    Vr_filter = inner_vars[Vr_filter_var]
    Vi_filter = inner_vars[Vi_filter_var]

    #Get parameters
    local_ix_params = get_local_parameter_ix(dynamic_device, PSY.KauraPLL)
    internal_params = @view device_parameters[local_ix_params]
    _, kp_pll, ki_pll = internal_params
    ω_ref = device_parameters[ω_ref_ix]

    #Get initial guess
    θ0_pll = atan(Vi_filter, Vr_filter)
    Vpll_d0 = Vr_filter
    Vpll_q0 = 0.0
    ϵ_pll0 = 0.0

    function f!(out, x)
        vpll_d = x[1]
        vpll_q = x[2]
        ϵ_pll = x[3]
        θ_pll = x[4]

        V_dq_pll = ri_dq(θ_pll + pi / 2) * [Vr_filter; Vi_filter]

        angle = atan(vpll_q, vpll_d)
        out[1] = (V_dq_pll[d] - vpll_d)
        out[2] = (V_dq_pll[q] - vpll_q)
        out[3] = angle
        out[4] = (kp_pll * angle + ki_pll * ϵ_pll)
    end

    x0 = [Vpll_d0, Vpll_q0, ϵ_pll0, θ0_pll]
    sol = NLsolve.nlsolve(f!, x0; ftol = STRICT_NLSOLVE_F_TOLERANCE)
    if !NLsolve.converged(sol)
        @warn("Initialization in PLL failed")
    else
        sol_x0 = sol.zero

        #Obtain indices for component w/r to device
        local_ix = get_local_state_ix(dynamic_device, PSY.KauraPLL)

        #Update guess of PLL states
        pll_states = @view device_states[local_ix]
        pll_states[1] = sol_x0[1]
        pll_states[2] = sol_x0[2]
        pll_states[3] = sol_x0[3]
        pll_states[4] = sol_x0[4]

        #Update guess of frequency estimator
        inner_vars[ω_freq_estimator_var] = ω_ref
        inner_vars[θ_freq_estimator_var] = sol_x0[4]
    end
end

function initialize_frequency_estimator!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{C, O, IC, DC, PSY.ReducedOrderPLL, F, L},
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    O <: PSY.OuterControl,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}
    Vr_filter = inner_vars[Vr_filter_var]
    Vi_filter = inner_vars[Vi_filter_var]

    #Get parameters
    pll_control = PSY.get_freq_estimator(dynamic_device)
    kp_pll = PSY.get_kp_pll(pll_control)
    ki_pll = PSY.get_ki_pll(pll_control)

    #Get initial guess
    θ0_pll = atan(Vi_filter, Vr_filter)
    Vpll_q0 = 0.0
    ϵ_pll0 = 0.0

    function f!(out, x)
        vpll_q = x[1]
        ϵ_pll = x[2]
        θ_pll = x[3]

        V_dq_pll = ri_dq(θ_pll + pi / 2) * [Vr_filter; Vi_filter]

        out[1] = V_dq_pll[q] - vpll_q
        out[2] = vpll_q
        out[3] = kp_pll * vpll_q + ki_pll * ϵ_pll
    end

    x0 = [Vpll_q0, ϵ_pll0, θ0_pll]
    sol = NLsolve.nlsolve(f!, x0; ftol = STRICT_NLSOLVE_F_TOLERANCE)
    if !NLsolve.converged(sol)
        @warn("Initialization in PLL failed")
    else
        sol_x0 = sol.zero

        #Obtain indices for component w/r to device
        local_ix = get_local_state_ix(dynamic_device, PSY.ReducedOrderPLL)

        #Update guess of PLL states
        pll_states = @view device_states[local_ix]
        pll_states[1] = sol_x0[1]
        pll_states[2] = sol_x0[2]
        pll_states[3] = sol_x0[3]

        #Update guess of frequency estimator
        inner_vars[ω_freq_estimator_var] = device_parameters[ω_ref_ix]
        inner_vars[θ_freq_estimator_var] = sol_x0[3]
    end
    return
end

function initialize_frequency_estimator!(
    device_states,
    device_parameters,
    static::PSY.StaticInjection,
    dynamic_device::DynamicWrapper{
        PSY.DynamicInverter{C, O, IC, DC, PSY.FixedFrequency, F, L},
    },
    inner_vars::AbstractVector,
) where {
    C <: PSY.Converter,
    O <: PSY.OuterControl,
    IC <: PSY.InnerControl,
    DC <: PSY.DCSource,
    F <: PSY.Filter,
    L <: Union{Nothing, PSY.InverterLimiter},
}
    #Get parameters
    local_ix_params = get_local_parameter_ix(dynamic_device, PSY.FixedFrequency)
    internal_params = @view device_parameters[local_ix_params]
    frequency = internal_params[1]

    #Update guess of frequency estimator
    inner_vars[ω_freq_estimator_var] = frequency
    return
end
