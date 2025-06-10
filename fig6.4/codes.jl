using CSV
using Colors
using DataFrames
using QuranTree
using Yunir
using Makie
using CairoMakie
using MakieThemes
using HTTP
using Statistics

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

crps, tnzl = load(QuranData());
crpstbl = table(crps)

qrn_order_url = "https://raw.githubusercontent.com/alstat/QuranData/main/revelation_order.txt"
http_response = HTTP.get(qrn_order_url)
quran_order = DataFrame(CSV.File(http_response.body, header=true, delim="\t"))
quran_order |> show

ayah_freq = combine(
    groupby(crpstbl.data, :chapter),
    :verse => x -> length(unique(x))
);

char_freq = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :form => x -> sum(length.(x))
)

word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
)

ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);

vcat(ayah_len[!, 2]...)

char_len = combine(
    groupby(char_freq, :chapter),
    :form_function => x -> Ref(vcat(x))
)

char_freq = DataFrame(
    chapter=ayah_len[!,:chapter],
    form_function_function=sum.(char_len[!,:form_function_function])
);

word_freq = DataFrame(
    chapter=ayah_len[!,:chapter],
    word_function=sum.(ayah_len[!,:word_function_function])
);

xs = Int64[]; j = 1
for i in ayah_len[!,:chapter]
    xs = vcat(xs, repeat([i], inner=length(ayah_len[j,:word_function_function])))
    j += 1
end
ys = vcat(ayah_len[!,:word_function_function]...);
place_rev = string.(sort(quran_order, :Number)[!,:Type]);
colors = [parse(Color, i) for i in current_theme[:swatch]]

df = DataFrame(
    chapter=ayah_len[!, :chapter], 
    ayah_freq=ayah_freq[!, :verse_function],
    word_freq=word_freq[!, :word_function],
    word_len_var=std.(ayah_len[!,:word_function_function]),
    word_len_mu=mean.(ayah_len[!,:word_function_function]),
    char_len_var=std.(char_len[!,:form_function_function]),
    char_len_mu=mean.(char_len[!,:form_function_function]),
    asbab=place_rev
)

ayah_len[!, :place_rev] = place_rev

# ayah mean meccan
mean(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))
median(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))
std(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))

# ayah mean medinan
mean(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))
median(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))
std(map(x -> length(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))

# word mean meccan
mean(vcat(ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]...))
median(vcat(ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]...))
std(vcat(ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]...))

# word mean medinan
mean(vcat(ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]...))
median(vcat(ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]...))
std(vcat(ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]...))

# ave. words per ayah
mean(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))
median(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))
std(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Meccan", :][!, 2]))

mean(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))
median(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))
std(map(x -> mean(x), ayah_len[ayah_len[!,:place_rev] .== "Medinan", :][!, 2]))

char_len[!, :place_rev] = place_rev
mean(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Meccan", :][!, 2]))
median(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Meccan", :][!, 2]))
std(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Meccan", :][!, 2]))

mean(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Medinan", :][!, 2]))
median(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Medinan", :][!, 2]))
std(map(x -> mean(x), char_len[char_len[!,:place_rev] .== "Medinan", :][!, 2]))

# using GLMakie

fig = Figure(size = (850, 900))
grd = GridLayout(fig[1,1], nrows=2, ncols=6)
ax1 = Axis(grd[1, 1:2], 
    xlabel = "Ayah Count",
    ylabel = "Word Variability per Ayah",
    title = "Word Variability vs. Ayah Count",
)

ax2 = Axis(grd[2, 1:2], 
    xlabel = "Ayah Count",
    ylabel = "Character Variability per Ayah",
    title = "Character Variability vs. Ayah Count",
)

ax3 = Axis(grd[1, 3:4], 
    xlabel = "Word Count",
    ylabel = "Word Variability per Ayah",
    title = "Word Variability vs. Word Count",
)

ax4 = Axis(grd[2, 3:4], 
    xlabel = "Word Count", 
    ylabel = "Character Variability per Ayah", 
    title = "Character Variability vs. Word Count",
)

ax5 = Axis3(grd[3, 1:2], 
    xlabel = "Surah", 
    ylabel = "Word Count", 
    zlabel = "Word Variability",
    title = "3D Scatter Plot of Word Variability",
    elevation = π/12,
    azimuth = 7π/4,
    yticks=(0:2000:4000, string.(0:2000:4000)),
)

ax6 = Axis3(grd[3, 3:4], 
    xlabel = "Surah", 
    ylabel = "Word Count", 
    zlabel = "Character Variability",
    title = "3D Scatter Plot of Character Variability",
    elevation = π/12,
    azimuth = 7π/4,
    yticks=(0:2000:4000, string.(0:2000:4000)),
)

linkyaxes!(ax1, ax3)
linkyaxes!(ax2, ax4)
linkxaxes!(ax1, ax2)
linkxaxes!(ax3, ax4)
hideydecorations!(ax3, grid=false)
hideydecorations!(ax4, grid=false)
hidexdecorations!(ax1, grid=false)
hidexdecorations!(ax3, grid=false)
colgap!(grd, -20)

# Split data by 'asbab'
meccan_indices = df.asbab .== "Meccan"
medinan_indices = df.asbab .== "Medinan"

# Colors for Meccan and Medinan
meccan_color = colors[2]
medinan_color = colors[7]

scatter!(ax1, 
    df.ayah_freq[meccan_indices], 
    df.word_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax1, 
    df.ayah_freq[medinan_indices], 
    df.word_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

scatter!(ax2, 
    df.ayah_freq[meccan_indices], 
    df.char_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax2, 
    df.ayah_freq[medinan_indices], 
    df.char_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

scatter!(ax3, 
    df.word_freq[meccan_indices], 
    df.word_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax3, 
    df.word_freq[medinan_indices], 
    df.word_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

scatter!(ax4, 
    df.word_freq[meccan_indices], 
    df.char_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax4, 
    df.word_freq[medinan_indices], 
    df.char_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

# Create 3D scatter plot
scatter!(ax5, 
    df.chapter[meccan_indices], 
    df.word_freq[meccan_indices], 
    df.word_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax5, 
    df.chapter[medinan_indices], 
    df.word_freq[medinan_indices], 
    df.word_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

scatter!(ax6, 
    df.chapter[meccan_indices], 
    df.word_freq[meccan_indices], 
    df.char_len_var[meccan_indices],
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax6, 
    df.chapter[medinan_indices], 
    df.word_freq[medinan_indices], 
    df.char_len_var[medinan_indices],
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

# Add legend
axislegend(ax3, position = :rb, framestroke = :black)

fig
# Save the figure
# save("plots/plot6.pdf", fig)

# Display the figure
fig