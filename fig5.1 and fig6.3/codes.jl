using CSV
using Colors
using DataFrames
using QuranTree
using Yunir
using Makie
using CairoMakie
using MakieThemes
using HTTP

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


# plot 3
# for boxplot
word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
);
word_len
ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);
ayah_len
xs = Int64[]; j = 1
for i in ayah_len[!,:chapter]
    xs = vcat(xs, repeat([i], inner=length(ayah_len[j,:word_function_function])))
    j += 1
end
ys = vcat(ayah_len[!,:word_function_function]...);
place_rev = string.(sort(quran_order, :Number)[!,:Type]);
colors = [parse(Color, i) for i in current_theme[:swatch]]

place_rev_order = string.(quran_order[!,:Type]);
colors_rev_order = [parse(Color, i) for i in current_theme[:swatch]]
ayah_len[!,"location"] = place_rev;

ayah_len[!,"location"] = place_rev;
ayah_len_loc = combine(groupby(ayah_len, :location),
    :word_function_function => x -> Ref(vcat(x...))
)
category_labels = vcat(
    repeat([ayah_len_loc[1,:location]], inner=length(ayah_len_loc[1,2])),
    repeat([ayah_len_loc[2,:location]], inner=length(ayah_len_loc[2,2]))
);
data_array = vcat(
    ayah_len_loc[1,2],ayah_len_loc[2,2]
);
f = Figure(resolution=(500, 500));
rainclouds!(Axis(
    f[1, 1], xlabel="Word Count per Ayah",
    yticks=(1:0.5:2.5, ["Meccan", "", "Medinan", ""])
    ), category_labels, data_array;
    orientation=:horizontal,
    plot_boxplots = true, cloud_width=0.5, clouds=hist, hist_bins=50,
    color = colors[[2,7]][indexin(category_labels, unique(category_labels))])
    
f
# save("plots/plot3.pdf", f)