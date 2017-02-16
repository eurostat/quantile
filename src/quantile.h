#ifndef __GSL_QUANTILE_H__
#define __GSL_QUANTILE_H__

#include <stddef.h>

#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS /* empty */
# define __END_DECLS /* empty */
#endif

__BEGIN_DECLS

;
#ifndef __QUANTILE_LONG_DOUBLE_FROM_GSL__
#define __QUANTILE_LONG_DOUBLE_FROM_GSL__
double *quantile_long_double_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_DOUBLE_FROM_GSL__
#define __QUANTILE_DOUBLE_FROM_GSL__
double *quantile_double_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_FLOAT_FROM_GSL__
#define __QUANTILE_FLOAT_FROM_GSL__
double *quantile_float_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_ULONG_FROM_GSL__
#define __QUANTILE_ULONG_FROM_GSL__
double *quantile_ulong_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_LONG_FROM_GSL__
#define __QUANTILE_LONG_FROM_GSL__
double *quantile_long_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_UINT_FROM_GSL__
#define __QUANTILE_UINT_FROM_GSL__
double *quantile_uint_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_INT_FROM_GSL__
#define __QUANTILE_INT_FROM_GSL__
double *quantile_int_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_USHORT_FROM_GSL__
#define __QUANTILE_USHORT_FROM_GSL__
double *quantile_ushort_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_SHORT_FROM_GSL__
#define __QUANTILE_SHORT_FROM_GSL__
double *quantile_short_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_UCHAR_FROM_GSL__
#define __QUANTILE_UCHAR_FROM_GSL__
double *quantile_uchar_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);
#endif
#ifndef __QUANTILE_CHAR_FROM_GSL__
#define __QUANTILE_CHAR_FROM_GSL__
double *quantile_char_from_gsl(char data[], size_t N, const double probs[], size_t n, int type);

__END_DECLS


#endif /* __GSL_QUANTILE_H__ */
