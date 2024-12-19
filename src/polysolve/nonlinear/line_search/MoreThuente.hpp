#pragma once

#include "LineSearch.hpp"

namespace polysolve::nonlinear::line_search
{
    class MoreThuente : public LineSearch
    {
    public:
        using Superclass = LineSearch;
        using typename Superclass::Scalar;
        using typename Superclass::TVector;

        MoreThuente(const json &params, spdlog::logger &logger);

        virtual std::string name() const override { return "More-Thuente"; }

    protected:
        virtual double compute_descent_step_size(
            const TVector &x,
            const TVector &delta_x,
            Problem &objFunc,
            const bool use_grad_norm,
            const double old_energy,
            const TVector &old_grad,
            const double starting_step_size) override;

    private:
        double wolfe_c1;
        double wolfe_c2;
        int max_iterations;
        double max_step_size;
    };
} // namespace polysolve::nonlinear::line_search
