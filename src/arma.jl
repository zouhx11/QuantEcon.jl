#=

@authors: Doc-Jin Jang, Jerry Choi, Thomas Sargent, John Stachurski

Provides functions for working with and visualizing scalar ARMA processes.

@date: Thu Aug 21 11:09:30 EST 2014

References
----------

Simple port of the file quantecon.arma

http://quant-econ.net/arma.html
=#

import PyPlot.plt
using DSP

type ARMA
    phi::Vector      # AR parameters phi_1, ..., phi_p
    theta::Vector    # MA parameters theta_1, ..., theta_q
    p::Integer       # Number of AR coefficients
    q::Integer       # Number of MA coefficients
    sigma::Real      # Variance of white noise
    ma_poly::Vector  # MA polynomial --- filtering representatoin
    ar_poly::Vector  # AR polynomial --- filtering representation
end

function ARMA{T <: Real}(phi::Union(Vector{T}, T), theta::Union(Vector{T}, T), sigma::T)
    # Build signal processing representation of polynomials
    p = length(phi)
    q = length(theta)
    ma_poly = [1.0, theta]
    ar_poly = [1.0, -phi]
    return ARMA(phi, theta, p, q, sigma, ma_poly, ar_poly)
end

function spectral_density(arma::ARMA; res=512, two_pi=true)
    wmax = two_pi ? 2pi : pi
    w = linspace(0, wmax, res)
    tf = TFFilter(reverse(arma.ma_poly), reverse(arma.ar_poly))
    h = freqz(tf, w)
    spect = arma.sigma^2 * abs(h).^2
    return w, spect
end

function autocovariance(arma::ARMA; num_autocov=16)
    (w, spect) = spectral_density(arma)
    acov = real(Base.ifft(spect))
    # num_autocov should be <= len(acov) / 2
    return acov[1:num_autocov]
end

function impulse_response(arma::ARMA; impulse_length=30)
    err_msg = "Impulse length must be greater than number of AR coefficients"
    @assert impulse_length >= arma.p err_msg
    # == Pad theta with zeros at the end == #
    theta = [arma.theta, zeros(impulse_length - arma.q)]
    psi_zero = 1.0
    psi = Array(Float64, impulse_length)
    for j = 1:impulse_length
        psi[j] = theta[j] 
        for i = 1:min(j, arma.p)
            psi[j] += arma.phi[i] * (j-i > 0 ? psi[j-i] : psi_zero)
        end
    end
    return [psi_zero, psi[1:end-1]]
end


# == Plot functions == #

function plot_spectral_density(arma::ARMA; ax=None, show=true)
    (w, spect) = spectral_density(arma, two_pi=false)
    if show
        fig, ax = plt.subplots()
    end
    ax[:set_xlim]([0, pi])
    ax[:set_title]("Spectral density")
    ax[:set_xlabel]("frequency")
    ax[:set_ylabel]("spectrum")
    ax[:semilogy](w, spect, axes=ax, color="blue", lw=2, alpha=0.7)
    if show
        plt.show()
    else
        return ax
    end
end


function plot_autocovariance(arma::ARMA; ax=None, show=true)
    acov = autocovariance(arma)
    n = length(acov)
    if show
        fig, ax = plt.subplots()
    end
    ax[:set_title]("Autocovariance")
    ax[:set_xlim](-0.5, n - 0.5)
    ax[:set_xlabel]("time")
    ax[:set_ylabel]("autocovariance")
    ax[:stem](0:(n-1), acov)
    if show
        plt.show()
    else
        return ax
    end
end

function plot_impulse_response(arma::ARMA; ax=None, show=true)
    psi = impulse_response(arma)
    n = length(psi)
    if show
        fig, ax = plt.subplots()
    end
    ax[:set_title]("Impulse response")
    ax[:set_xlim](-0.5, n - 0.5)
    ax[:set_xlabel]("time")
    ax[:set_ylabel]("response")
    ax[:stem](0:(n-1), psi)
    if show
        plt.show()
    else
        return ax
    end
end



phi = [0.5]
theta = [0.0, -0.8]
sigma = 1.0
lp = ARMA(phi, theta, sigma)
#plot_spectral_density(lp)
plot_impulse_response(lp)

#fig, axes = plt.subplots(2, 2, figsize=(6, 6))
#plt.semilogy(w, spect, axes=axes[1, 1])
