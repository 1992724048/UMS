// 2026-04-24

namespace WebAPI.Struct {
    public record PageResult<T> {
        public List<T> Data { get; init; } = [];
        public long Total { get; init; }
        public int Page { get; init; }
        public int PageSize { get; init; }
    }
}
