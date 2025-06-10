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
using LinRegOutliers

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

df2 = sort(df, :char_len_mu)

reg = createRegressionSetting(@formula(char_len_var ~ char_len_mu), df2)
out_reg = lts(reg)

out_df = df2[out_reg["outliers"], :]

fig1 = Figure(size = (800, 800))
ax7 = Axis(fig1[1, 1], 
    xlabel = "Mean (Character) Ayah Length", 
    ylabel = "Std. Deviation of Ayah Length", 
    # zlabel = "Chapter",
    title = "With Sinai Outliers",
)

ax8 = Axis(fig1[1, 2], 
    xlabel = "Mean (Character) Ayah Length", 
    ylabel = "Std. Deviation of Ayah Length", 
    # zlabel = "Chapter",
    title = "With LTS Outlier Detection",
)

ax9 = Axis(fig1[2, 1], 
    xlabel = "Mean (Word) Ayah Length", 
    ylabel = "Std. Deviation of Ayah Length", 
    # zlabel = "Chapter",
    title = "With Sinai Outliers",
)

ax10 = Axis(fig1[2, 2], 
    xlabel = "Mean (Word) Ayah Length", 
    ylabel = "Std. Deviation of Ayah Length", 
    # zlabel = "Chapter",
    title = "With LTS Outlier Detection",
)

hideydecorations!(ax8, grid=false)
hideydecorations!(ax10, grid=false)
linkyaxes!(ax7, ax8)
linkyaxes!(ax9, ax10)
# linkxaxes!(ax7, ax9)
# linkxaxes!(ax8, ax10)

scatter!(ax7, 
    df2.char_len_mu[meccan_indices], 
    df2.char_len_var[meccan_indices], 
    # df2.chapter[meccan_indices], 
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax7, 
    df2.char_len_mu[medinan_indices], 
    df2.char_len_var[medinan_indices], 
    # df2.chapter[medinan_indices], 
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

text!(ax7, (vec(Array(df2[df2[!, :chapter] .== 73, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="73", align=(:left, :center))
text!(ax7, (vec(Array(df2[df2[!, :chapter] .== 85, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="85", align=(:left, :center))
text!(ax7, (vec(Array(df2[df2[!, :chapter] .== 103, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="103", align=(:left, :center))
text!(ax7, (vec(Array(df2[df2[!, :chapter] .== 53, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="53", align=(:left, :center))
text!(ax7, (vec(Array(df2[df2[!, :chapter] .== 74, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="74", align=(:left, :center))

scatter!(ax8, 
    df2.char_len_mu[meccan_indices], 
    df2.char_len_var[meccan_indices], 
    # df2.chapter[meccan_indices], 
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax8, 
    df2.char_len_mu[medinan_indices], 
    df2.char_len_var[medinan_indices], 
    # df2.chapter[medinan_indices], 
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

for i in out_df[!,:chapter]
    text!(ax8, (vec(Array(df2[df2[!, :chapter] .== i, [:char_len_mu, :char_len_var]])) .+ [4, 0])..., text="$i", align=(:left, :center))
end

lreg(x) = out_reg["betas"][1] .+  out_reg["betas"][2].*x 

lines!(ax8, 
    df2.char_len_mu, 
    lreg(df2.char_len_mu), 
    color = colors[6], 
    linewidth = 2,
    label = "Fitted LTS"
)

# -

reg = createRegressionSetting(@formula(word_len_var ~ word_len_mu), df2)
out_reg = lts(reg)

out_df = df2[out_reg["outliers"], :]

scatter!(ax9, 
    df2.word_len_mu[meccan_indices], 
    df2.word_len_var[meccan_indices], 
    # df2.chapter[meccan_indices], 
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax9, 
    df2.word_len_mu[medinan_indices], 
    df2.word_len_var[medinan_indices], 
    # df2.chapter[medinan_indices], 
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

text!(ax9, (vec(Array(df2[df2[!, :chapter] .== 73, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="73", align=(:left, :center))
text!(ax9, (vec(Array(df2[df2[!, :chapter] .== 85, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="85", align=(:left, :center))
text!(ax9, (vec(Array(df2[df2[!, :chapter] .== 103, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="103", align=(:left, :center))
text!(ax9, (vec(Array(df2[df2[!, :chapter] .== 53, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="53", align=(:left, :center))
text!(ax9, (vec(Array(df2[df2[!, :chapter] .== 74, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="74", align=(:left, :center))

scatter!(ax10, 
    df2.word_len_mu[meccan_indices], 
    df2.word_len_var[meccan_indices], 
    # df2.chapter[meccan_indices], 
    color = meccan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Meccan"
)

scatter!(ax10, 
    df2.word_len_mu[medinan_indices], 
    df2.word_len_var[medinan_indices], 
    # df2.chapter[medinan_indices], 
    color = medinan_color,
    markersize = 15,
    alpha = 0.7,
    label = "Medinan"
)

for i in out_df[!,:chapter]
    text!(ax10, (vec(Array(df2[df2[!, :chapter] .== i, [:word_len_mu, :word_len_var]])) .+ [0.5, 0])..., text="$i", align=(:left, :center))
end

lreg(x) = out_reg["betas"][1] .+  out_reg["betas"][2].*x 

lines!(ax10, 
    df2.word_len_mu, 
    lreg(df2.word_len_mu), 
    color = colors[6], 
    linewidth = 2,
    label = "Fitted LTS"
)

axislegend(ax8, position = :rb, framestroke = :black)

fig1
# save("plots/plot7.pdf", fig1)