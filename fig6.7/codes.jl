using DataFrames
using QuranTree
using Makie
using Colors
using CairoMakie
using MakieThemes
using Yunir

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
crps_tbl = table(crps)
tnzl_tbl = table(tnzl)

function last_syllable(bw_texts)
    bw1_texts = Array{String,1}()
    bw2_texts = Array{String,1}()
    bw3_texts = Array{String,1}()
    for bw_text in bw_texts
        @info bw_text
        push!(bw1_texts, replace(bw_text[end-3:end-2], "o" => ""))
        push!(bw2_texts, replace(bw_text[end-3:end-1], "o" => ""))
        push!(bw3_texts, replace(bw_text[end-4:end-1], "o" => ""))
    end
    return bw1_texts, bw2_texts, bw3_texts
end

function encode_to_number(ychars::Array{String})
    y = unique(ychars)
    y_dict = Dict()
    for i in eachindex(y)
        if i == 1
            y_dict[y[i]] = i
        end
        
        if y[i] .∈ Ref(Set(keys(y_dict)))
            continue
        else
            y_dict[y[i]] = i
        end
    end
    y_vec = Array{Int64,1}()
    for i in ychars
        push!(y_vec, y_dict[i])
    end
    return y_vec, y_dict # scaling to 100 since algo will fail saying range step cannot 0
end

bw_texts = verses(crps_tbl[1])
y1_chars, y2_chars, y3_chars = last_syllable(bw_texts)
y1, y1_dict = encode_to_number(y1_chars)
y2, y2_dict = encode_to_number(y2_chars)
y3, y3_dict = encode_to_number(y3_chars)

#### Analysis

lsyllables = Vector{Vector{String}}[]
for surah in 1:114
    bw_texts = encode.(verses(tnzl_tbl[surah]))
    y1_chars, y2_chars, y3_chars = last_syllable(bw_texts)
    push!(lsyllables, [y1_chars, y2_chars, y3_chars])
end

lsyllables[1][1]

function find_similar_last_syllable(lsyllables, crps_tbl, num_syllables)
    vrs_countdf = combine(groupby(crps_tbl.data, [:chapter]), 
        :verse => x -> length(unique(x)),
    )
    
    issimilar = zeros(Float64, 114, 114)
    for src_surah in 1:114
        src_df = vrs_countdf[vrs_countdf.chapter .== src_surah, :verse_function]
        tgt_surahs = vrs_countdf[vrs_countdf.verse_function .== src_df[1], :chapter]
        
        # if length(tgt_surahs) == 1
        #     continue
        # else
        #     # tgt_surahs = tgt_surahs[tgt_surahs .!= src_surah]
        # end

        src_lsyllable = lsyllables[src_surah][num_syllables]
        
        for tgt_surah in tgt_surahs
            tgt_lsyllable = lsyllables[tgt_surah][num_syllables]
            issimilar[src_surah, tgt_surah] = sum(src_lsyllable .== tgt_lsyllable) / length(src_lsyllable)
        end
    end
    return issimilar
end 

# surah_similar = Dict();
# for i in 1:114
#     surah_similar[i] = find_similar_last_syllable(lsyllables, crps_tbl, i, 1)
# end



data_matrix = find_similar_last_syllable(lsyllables, crps_tbl, 1)
findall(x -> x != 0.0, data_matrix[1,:])

sort(unique(data_matrix))
data_matrix[1, 107]
fig = Figure(size=(700, 700))
ax = Axis(fig[1,1], 
    xlabel = "Surah", 
    ylabel = "Surah", 
    xticks = (4:10:114, string.(4:10:114)),
    yticks = (4:10:114, string.(4:10:114)),
    aspect = AxisAspect(1.),
)

centers_x = 1:size(data_matrix)[1]
centers_y = 1:size(data_matrix)[2]
hm = heatmap!(ax, 
    centers_x, centers_y, data_matrix, 
    colormap=colors[[5,6,2]],
    colorrange=(0, 1)
)
Colorbar(fig[:, end+1], hm)
fig


# save("plots/rhythmic_last_syllable_similarities.svg", fig)