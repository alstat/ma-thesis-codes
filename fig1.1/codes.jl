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

mean(ayah_freq[!,:verse_function])
median(ayah_freq[!,:verse_function])
std(ayah_freq[!,:verse_function])

# for boxplot
char_freq = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :form => x -> sum(length.(x))
)

# for boxplot
word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
);

ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);
word_freq = DataFrame(
    chapter=ayah_len[!,:chapter],
    word_function=sum.(ayah_len[!,:word_function_function])
);


ayah_len[!,:word_function_function]

mean(word_freq[!,:word_function])
median(word_freq[!,:word_function])
std(word_freq[!,:word_function])

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

xs_color = Int64[]; j=1
for i in place_rev
    xs_color = vcat(xs_color, repeat([i], inner=length(ayah_len[j, :word_function_function])))
    j += 1
end

# -----------

f = Figure(size=(800, 800));
xticks = vcat(1, 19:19:114...)
grd = f[1,1] = GridLayout()
gax = grd[1,1:30] = GridLayout()
max = grd[1,31:33] = GridLayout()

ax_bar = Axis(
    gax[1,1], ylabel="Ayah Count",
    xticks=(xticks, string.(xticks))
)
ax_barhist = Axis(max[1,2:7])
ax_barbox = Axis(max[1,1])

wx_bar = Axis(
    gax[2,1], ylabel="Word Count",
    xticks=(xticks, string.(xticks)),
    yticks=([0, 2500, 5000], ["0", "2.5k", "5.0k"])
)
wx_barhist = Axis(max[2,2:7])
wx_barbox = Axis(max[2,1])

ax_box = Axis(
    gax[3,1], xlabel="Surah", ylabel="Word Count Per Ayah\n",
    xticks=(xticks, string.(xticks))
)
ax_boxhist = Axis(max[3,2:7])
ax_boxbox = Axis(max[3,1])

cx_box = Axis(
    gax[4,1], xlabel="Surah", ylabel="Character Count Per Ayah",
    xticks=(xticks, string.(xticks))    
)
cx_boxhist = Axis(max[4,2:7])
cx_boxbox = Axis(max[4,1])

barplot!(ax_bar, ayah_freq.chapter, ayah_freq.verse_function, color=colors[[2,7]][indexin(place_rev, ["Meccan", "Medinan"])], label="Meccan")
hidexdecorations!(ax_bar, grid=false)
surah_numbers = ayah_freq.chapter[ayah_freq.verse_function .> 180][[1,3:end...]]
surah_heights = [290, 210, 230, 185]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    text!(ax_bar,  surah_labels, position=(surah, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(ax_barhist, ayah_freq.verse_function, direction=:y,
    color=colors[5])
hidedecorations!(ax_barhist)
hidespines!(ax_barhist)
boxplot!(ax_barbox, repeat([1], inner=length(ayah_freq.verse_function)),
    ayah_freq.verse_function, color=colors[3], mediancolor=colors[6],
    whiskercolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(ax_barbox)
hidespines!(ax_barbox)
ylims!(ax_bar, low=-40, high=310)
ylims!(ax_barbox, low=-40, high=310)
ylims!(ax_barhist, low=-40, high=310)
linkyaxes!(ax_bar, ax_barbox, ax_barhist)

barplot!(wx_bar, word_freq.chapter, word_freq.word_function,
    color=colors[[2,7]][indexin(place_rev, ["Meccan", "Medinan"])])
hidexdecorations!(wx_bar, grid=false)
arrows!(wx_bar, [26], [1100], [2], [1230], color=current_theme[:line][1])
arrows!(wx_bar, [37], [700], [2], [950], color=current_theme[:line][1])
surah_numbers = [2, 7, 26, 37]
surah_heights = [6300, 3500, 3300, 2600]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    text!(wx_bar,  surah_labels, position=(surah, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(wx_barhist, word_freq.word_function, direction=:y,
    color=colors[5])
hidedecorations!(wx_barhist)
hidespines!(wx_barhist)
boxplot!(wx_barbox, repeat([1], inner=length(word_freq.word_function)),
    word_freq.word_function, color=colors[3], mediancolor=colors[6],
    whiskercolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(wx_barbox)
hidespines!(wx_barbox)
ylims!(wx_bar, low=-900, high=7000)
ylims!(wx_barbox, low=-900, high=7000)
ylims!(wx_barhist, low=-900, high=7000)
linkyaxes!(wx_bar, wx_barbox, wx_barhist)

boxplot!(ax_box, xs, ys, width=1.2, markersize=4, gap=0.3,
    color=colors[[2,7]][indexin(xs_color, ["Meccan", "Medinan"])], whiskercolor=colors[5], mediancolor=colors[5]);
hidexdecorations!(ax_box, grid=false)
density!(ax_boxhist, ys, direction=:y,
    color=colors[5])
hidedecorations!(ax_boxhist)
hidespines!(ax_boxhist)
boxplot!(ax_boxbox, repeat([1], inner=length(ys)), ys, color=colors[3],
    mediancolor=colors[6], whiskercolor=colors[6], width=0.1,
    markersize=4, gap=0.3);
hidedecorations!(ax_boxbox)
hidespines!(ax_boxbox)
linkyaxes!(ax_box, ax_boxbox, ax_boxhist)


boxplot!(cx_box, char_freq[!, :chapter], char_freq[!, :form_function], width=1.2, markersize=4, gap=0.3,
    color=colors[[2,7]][indexin(xs_color, ["Meccan", "Medinan"])], whiskercolor=colors[5], mediancolor=colors[5]);
density!(cx_boxhist, char_freq[!, :form_function], direction=:y,
    color=colors[5])
hidedecorations!(cx_boxhist)
hidespines!(cx_boxhist)
boxplot!(cx_boxbox, repeat([1], inner=length(char_freq[!, :form_function])), char_freq[!, :form_function], color=colors[3],
    mediancolor=colors[6], whiskercolor=colors[6], width=0.1,
    markersize=4, gap=0.3);
hidedecorations!(cx_boxbox)
hidespines!(cx_boxbox)
linkyaxes!(cx_box, cx_boxbox, cx_boxhist)
rowgap!(gax, 10)
colgap!(max, 1)
rowgap!(max, 10)
colgap!(grd, 5)

labels = ["Meccan", "Medinan"]
elements = [PolyElement(polycolor = colors[[2,7]][i]) for i in 1:length(labels)]
title = "Groups"

axislegend(ax_bar, elements, labels, title, orientation=:vertical)

f
# save("plots/plot1.pdf", f)
