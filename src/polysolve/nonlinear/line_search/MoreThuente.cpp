#include "more_thuente.hpp"
#include <polysolve/Utils.hpp>
#include <spdlog/spdlog.h>

namespace polysolve::nonlinear::line_search
{
    MoreThuente::MoreThuente(const json &params, spdlog::logger &logger)
        : Superclass(params, logger)
    {
        wolfe_c1 = params.at("line_search").at("MoreThuente").value("c1", 1e-4);
        wolfe_c2 = params.at("line_search").at("MoreThuente").value("c2", 0.9);
        max_iterations = params.at("line_search").at("MoreThuente").value("max_iterations", 20);
    }

    double MoreThuente::compute_descent_step_size(
        const TVector &x,
        const TVector &delta_x,
        Problem &objFunc,
        const bool use_grad_norm,
        const double old_energy,
        const TVector &old_grad,
        const double starting_step_size)
    {
        double step_size = starting_step_size;
        double low = 0.0;
        double high = std::numeric_limits<double>::infinity();
        double energy;
        TVector grad;

        for (int i = 0; i < max_iterations; ++i)
        {
            TVector new_x = x + step_size * delta_x;
            energy = objFunc(new_x);

            if (energy > old_energy + wolfe_c1 * step_size * old_grad.dot(delta_x))
            {
                high = step_size;
            }
            else
            {
                objFunc.gradient(new_x, grad);
                if (grad.dot(delta_x) < wolfe_c2 * old_grad.dot(delta_x))
                {
                    low = step_size;
                }
                else
                {
                    break; // Wolfe conditions satisfied
                }
            }

            if (high < std::numeric_limits<double>::infinity())
            {
                step_size = 0.5 * (low + high);
            }
            else
            {
                step_size *= 2.0; // Expand step size
            }

            m_logger.debug("Iteration {}: step_size = {}, energy = {}", i, step_size, energy);
        }

        if (step_size <= current_min_step_size() || step_size >= high)
        {
            m_logger.warn("More-Thuente line search failed to find a valid step size.");
            return NaN;
        }

        return step_size;
    }
} // namespace polysolve::nonlinear::line_search
