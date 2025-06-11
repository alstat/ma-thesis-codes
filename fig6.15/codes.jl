using CairoMakie
using Distributions
using LinearAlgebra
using Random

using Colors
using MakieThemes
CairoMakie.activate!(type = "svg")
active_theme = :dust

if active_theme == :earth
    Makie.set_theme!(ggthemr(:earth))
    current_theme = Dict(
        :background => "#36312C",
        :text       => ["#555555", "#F8F8F0"],
        :line       => ["#ffffff", "#827D77"],
        :gridline   => "#504940",
        :swatch     => ["#F8F8F0", "#DB784D", "#95CC5E", "#E84646", "#F8BB39", "#7A7267", "#E1AA93", "#168E7F", "#2B338E"],
        :gradient   => ["#7A7267", "#DB784D"]
    )
elseif active_theme == :dust
    Makie.set_theme!(ggthemr(:dust))
    current_theme = Dict(
        :background => "#FAF7F2",
        :text       => ["#5b4f41", "#5b4f41"],
        :line       => ["#8d7a64", "#8d7a64"],
        :gridline   => "#E3DDCC",
        :swatch     => ["#555555", "#db735c", "#EFA86E", "#9A8A76", "#F3C57B", "#7A6752", "#2A91A2", "#87F28A", "#6EDCEF"],
        :gradient   => ["#F3C57B", "#7A6752"]
    )
else
    error("No active_theme=" * string(active_theme))
end;
colors = [parse(Color, i) for i in current_theme[:swatch]]

# Function to convert Dirichlet samples to barycentric coordinates
function dirichlet_to_barycentric(samples)
    # For a triangle simplex in 3D space
    # Convert from Dirichlet distribution to barycentric coordinates
    n_samples = size(samples, 2)
    
    # Define the vertices of the equilateral triangle
    vertices = [
        [0, 0, 0],  # First vertex at origin
        [1, 0, 0],  # Second vertex
        [0.5, sqrt(3)/2, 0]  # Third vertex to form equilateral triangle
    ]
    
    # Convert to barycentric coordinates
    cartesian_coords = zeros(3, n_samples)
    for i in 1:n_samples
        # Linear combination of vertices weighted by Dirichlet samples
        cartesian_coords[:, i] = samples[1, i] * vertices[1] + 
                                 samples[2, i] * vertices[2] + 
                                 samples[3, i] * vertices[3]
    end
    
    return cartesian_coords
end

# Function to add dimension labels to the sides of the triangle
function add_dimension_labels!(ax)
    # Define coordinates for the midpoints of each side
    side1_midpoint = (0.5, 0) # Bottom side (between v₁ and v₂)
    side2_midpoint = (0.75, sqrt(3)/4) # Right side (between v₂ and v₃)
    side3_midpoint = (0.25, sqrt(3)/4) # Left side (between v₃ and v₁)
    
    # Add labels with slight offsets for better visibility
    text!(ax, "b₁", position=side1_midpoint, align=(:center, :top), offset=(0, -5))
    text!(ax, "b₂\t", position=side3_midpoint, align=(:right, :center), offset=(-5, 0))
    text!(ax, "\tb₃", position=side2_midpoint, align=(:left, :center), offset=(5, 0))
end

# Function to visualize Dirichlet samples in the simplex
function visualize_dirichlet_simplex(alpha_values, n_samples=100_000)
    # Generate samples from Dirichlet distribution
    dirichlet_dist = Dirichlet(alpha_values)
    samples = rand(dirichlet_dist, n_samples)
    
    # Convert samples to cartesian coordinates
    coords = dirichlet_to_barycentric(samples)
    
    # Create figure and axis
    fig = Figure(resolution=(800, 800))
    ax = Axis(fig[1, 1], 
              aspect=DataAspect(),
              xlabel="x", ylabel="y",
              title="Dirichlet Simplex (α = $alpha_values)")
    
    # Define triangle vertices
    triangle_vertices = [[0, 0], [1, 0], [0.5, sqrt(3)/2]]
    
    # Fill the triangle with a light color background
    poly!(ax, Point2f[Point2f(v[1], v[2]) for v in triangle_vertices], 
          color=(:lightblue, 0.3))
    
    # Plot the triangle outline
    lines!(ax, [first(v) for v in [triangle_vertices..., triangle_vertices[1]]], 
           [last(v) for v in [triangle_vertices..., triangle_vertices[1]]], 
           color=:black, linewidth=2)
    
    # Plot the samples
    scatter!(ax, coords[1, :], coords[2, :], 
             markersize=3, alpha=0.4)
    
    # Add vertex labels
    text!(ax, "v₁ (1,0,0)", position=(0, 0), align=(:right, :top))
    text!(ax, "v₂ (0,1,0)", position=(1, 0), align=(:left, :top))
    text!(ax, "v₃ (0,0,1)", position=(0.5, sqrt(3)/2), align=(:center, :bottom))
    
    # Add dimension labels to the sides
    add_dimension_labels!(ax)
    
    # Adjust limits to see full triangle with some margin
    xlims!(ax, -0.1, 1.1)
    ylims!(ax, -0.1, 0.9)
    
    return fig
end

# Visualize different Dirichlet distributions
function compare_dirichlet_distributions()
    # Create a figure with multiple subplots
    fig = Figure(size=(800, 600))
    
    # Define different parameter sets for the Dirichlet distribution
    alpha_sets = [
        [1.0, 1.0, 1.0],     # Uniform distribution on the simplex
        [5.0, 5.0, 5.0],     # Concentrated in the center
        [0.5, 0.5, 0.5],     # Concentrated at the vertices
        [5.0, 1.0, 1.0],     # Biased towards first component
        [1.0, 5.0, 1.0],     # Biased towards second component
        [1.0, 1.0, 5.0]      # Biased towards third component
    ]
    
    # Create subplots
    for (i, alpha) in enumerate(alpha_sets)
        row, col = divrem(i-1, 3)
        ax = Axis(fig[row+1, col+1], 
                  aspect=DataAspect(),
                  title="α = $alpha")
        
        # Generate samples and convert to cartesian coordinates
        dirichlet_dist = Dirichlet(alpha)
        samples = rand(dirichlet_dist, 10_000)
        coords = dirichlet_to_barycentric(samples)
        
        # Define triangle vertices
        triangle_vertices = [[0, 0], [1, 0], [0.5, sqrt(3)/2]]
        
        # Fill the triangle with a background color (varies by subplot)
        poly!(ax, Point2f[Point2f(v[1], v[2]) for v in triangle_vertices], 
              color=colors[5])
        
        # Plot triangle outline
        lines!(ax, [first(v) for v in [triangle_vertices..., triangle_vertices[1]]], 
               [last(v) for v in [triangle_vertices..., triangle_vertices[1]]], 
               color=:black, linewidth=1.5)
        
        # Plot samples
        scatter!(ax, coords[1, :], coords[2, :], 
                 markersize=3, alpha=0.5, color=colors[2])
        
        # Add dimension labels to each subplot
        add_dimension_labels!(ax)
        
        # Adjust limits
        xlims!(ax, -0.1, 1.1)
        ylims!(ax, -0.1, 0.9)
        hidedecorations!(ax)
        hidespines!(ax)
    end
    
    return fig
end

# Set random seed for reproducibility
Random.seed!(123)

# Example 1: Visualize a single Dirichlet distribution
fig1 = visualize_dirichlet_simplex([2.0, 2.0, 2.0])
# save("plots/dirichlet_single.png", fig1)

# Example 2: Compare different Dirichlet distributions
fig2 = compare_dirichlet_distributions()
# save("plots/dirichlet_comparison.png", fig2)
fig2

# println("Visualization completed and saved as PNG files.")